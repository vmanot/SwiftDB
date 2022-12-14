//
// Copyright (c) Vatsal Manot
//

import CoreData
import CorePersistence
import Diagnostics
import Foundation
import Merge
import Swallow

extension _CoreData {
    public typealias Database = CoreDataDatabase
}

public final class CoreDataDatabase: CancellablesHolder, SwiftDB.LocalDatabase, ObservableObject {
    private let logger = os.Logger(subsystem: "com.vmanot.SwiftDB", category: "_CoreData.Database")
    private let setupTasksQueue = TaskQueue()
    
    public typealias Record = _CoreData.DatabaseRecord
    public typealias RecordSpace = _CoreData.DatabaseRecordSpace
    
    let schema: _Schema
    
    public let configuration: Configuration
    public var state: State
    public let context: Context
    
    public var mainRecordSpace: _CoreData.DatabaseRecordSpace?
    
    public var nsPersistentContainer: NSPersistentContainer!
    
    public init(
        runtime: _SwiftDB_Runtime,
        schema: _Schema?,
        configuration: Configuration,
        state: State?
    ) throws {
        self.schema = try schema.unwrap()
        self.configuration = configuration
        self.state = state ?? .init()
        self.context = .init(runtime: runtime, schema: self.schema, schemaAdaptor: .init(schema: self.schema))
        
        try createFoldersIfNecessary()
        
        self.nsPersistentContainer = .init(
            name: configuration.name,
            managedObjectModel: try schema.map({ try .init($0) })
        )
        
        try setupPersistentStoreDescription()
    }
    
    private func createFoldersIfNecessary() throws {
        if let location = configuration.location {
            guard location.pathExtension == "sqlite" else {
                throw ConfigurationError.customLocationPathExtensionMissing
            }
            
            let locationContainer = location.deletingLastPathComponent()
            
            if !FileManager.default.directoryExists(at: locationContainer) {
                try FileManager.default.createDirectory(at: locationContainer, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
    
    private func loadPersistentStoresIfNeeded() async throws {
        try setupPersistentStoreDescription()
        
        guard nsPersistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else {
            return
        }
        
        try createFoldersIfNecessary()
        
        try await nsPersistentContainer.loadPersistentStores()
        
        nsPersistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        mainRecordSpace = RecordSpace(
            databaseContext: context,
            managedObjectContext: self.nsPersistentContainer.viewContext,
            affectedStores: nil
        )
        
        objectWillChange.send()
    }
    
    private func setupPersistentStoreDescription() throws {
        // Clear default store descriptions if an explicit location has been provided.
        if configuration.location != nil {
            nsPersistentContainer.persistentStoreDescriptions = []
        }
        
        guard nsPersistentContainer.persistentStoreDescriptions.isEmpty else {
            return
        }
        
        if let sqliteStoreURL = sqliteStoreURL {
            let storeDescription = NSPersistentStoreDescription(url: sqliteStoreURL)
            
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.type = NSSQLiteStoreType
            
            nsPersistentContainer.persistentStoreDescriptions = [storeDescription]
        }
        
        let description = try nsPersistentContainer.persistentStoreDescriptions.first.unwrap()
        
        if let cloudKitContainerIdentifier = configuration.cloudKitContainerIdentifier {
            description.cloudKitContainerOptions = .init(containerIdentifier: cloudKitContainerIdentifier)
            
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
    }
}

// MARK: - Conformances -

extension _CoreData.Database {
    enum ConfigurationError: Error {
        case customLocationPathExtensionMissing
    }
    
    public struct Configuration: Codable, Sendable {
        public let name: String
        public let location: URL?
        public let cloudKitContainerIdentifier: String?
        
        public init(
            name: String,
            location: URL?,
            cloudKitContainerIdentifier: String?
        ) {
            self.name = name
            self.location = location
            self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        }
    }
    
    public struct State: Codable, Equatable, Sendable {
        public var schemaHistory: _SchemaHistory
        
        public init() {
            self.schemaHistory = .init()
        }
    }
    
    @discardableResult
    public func fetchAllAvailableZones() -> AnyTask<[Zone], Error> {
        Task { @MainActor in
            try await setupTasksQueue.perform {
                try await self.loadPersistentStoresIfNeeded()
            }
            
            return try nsPersistentContainer
                .persistentStoreCoordinator
                .persistentStores
                .map { store in
                    let description = try nsPersistentContainer.persistentStoreDescription(for: store).unwrap()
                    
                    return try _CoreData.Database.Zone(persistentStoreDescription: description)
                }
        }
        .convertToObservableTask()
    }
    
    @discardableResult
    public func fetchAllAvailableZones() async throws -> [Zone] {
        try await fetchAllAvailableZones().value
    }
    
    public func querySubscription(
        for request: ZoneQueryRequest
    ) throws -> QuerySubscription {
        try .init(recordSpace: mainRecordSpace.unwrap(), queryRequest: request)
    }
    
    public func transactionExecutor() throws -> TransactionExecutor {
        try .init(recordSpace: mainRecordSpace.unwrap())
    }
    
    public func recordSpace(forZones zones: [Zone]?) throws -> RecordSpace {
        RecordSpace(
            databaseContext: context,
            managedObjectContext: nsPersistentContainer.viewContext,
            affectedStores: zones?.map({ $0.id })
        )
    }
    
    public func delete() -> AnyTask<Void, Error> {
        @Sendable
        func deleteAllStoreFiles() throws {
            let allStoreFiles = self.allStoreFiles
            
            try allStoreFiles.forEach { url in
                if FileManager.default.fileExists(at: url) {
                    try FileManager.default.removeItem(at: url)
                }
            }
        }
        
        return Task { @MainActor in
            await MainActor.run {
                objectWillChange.send()
            }
            
            self.mainRecordSpace = nil
            
            if nsPersistentContainer.viewContext.hasChanges {
                nsPersistentContainer.viewContext.rollback()
                nsPersistentContainer.viewContext.reset()
            }
            
            try nsPersistentContainer.persistentStoreCoordinator.destroyAll()
            
            try deleteAllStoreFiles()
            
            self.nsPersistentContainer = NSPersistentContainer(
                name: self.nsPersistentContainer.name,
                managedObjectModel: self.nsPersistentContainer.managedObjectModel
            )
        }
        .convertToObservableTask()
    }
    
    private func allZones() throws -> [Zone] {
        try nsPersistentContainer.persistentStoreDescriptions.map({ try .init(persistentStoreDescription: $0) })
    }
}

extension _CoreData.Database: FolderEnclosable {
    public var topLevelFileContents: [URL.PathComponent] {
        get throws {
            try allZones().flatMap({ $0.topLevelFileContents }).distinct()
        }
    }
}

extension _CoreData.Database: Identifiable {
    public var id: String {
        name
    }
}

extension _CoreData.Database: Named {
    public var name: String {
        nsPersistentContainer.name
    }
}

// MARK: - Auxiliary -

extension _CoreData.Database {
    public var sqliteStoreURL: URL? {
        if let location = configuration.location {
            return location
        } else {
            return nsPersistentContainer.persistentStoreDescriptions.first?.url
        }
    }
    
    public var allStoreFiles: [URL] {
        var result: [URL] = []
        
        if let fileURL = sqliteStoreURL {
            let externalStorageFolderName = ".\(fileURL.deletingPathExtension().lastPathComponent)_SUPPORT"
            
            result.append(fileURL.deletingLastPathComponent().appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist"))
            result.append(fileURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            result.append(fileURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            result.append(fileURL.deletingLastPathComponent().appendingPathComponent(externalStorageFolderName, isDirectory: true))
            result.append(fileURL)
        }
        
        return result
    }
}
