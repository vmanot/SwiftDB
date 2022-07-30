//
// Copyright (c) Vatsal Manot
//

import CoreData
import Diagnostics
import Foundation
import Merge
import Swallow

class EnclosedEvolutionMigrationPolicy: NSEntityMigrationPolicy {
    
}

extension _CoreData {
    public final class Database: CancellablesHolder, SwiftDB.Database, ObservableObject {
        private let logger = os.Logger(subsystem: "com.vmanot.SwiftDB", category: "_CoreData.Database")
        
        enum ConfigurationError: Error {
            case customLocationPathExtensionMissing
        }
        
        public struct Configuration: Codable, Sendable {
            public let name: String
            public let location: URL?
            public let applicationGroupID: String?
            public let cloudKitContainerIdentifier: String?
            
            public init(
                name: String,
                location: URL?,
                applicationGroupID: String?,
                cloudKitContainerIdentifier: String?
            ) {
                self.name = name
                self.location = location
                self.applicationGroupID = applicationGroupID
                self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
            }
        }
        
        public struct State: Codable, Equatable, Sendable {
            var lastKnownSchema: DatabaseSchema?
        }
        
        public typealias RecordContext = _CoreData.DatabaseRecordContext
        
        let runtime: _SwiftDB_Runtime
        let schema: DatabaseSchema
        
        public let configuration: Configuration
        public var state: State
        public var viewContext: DatabaseRecordContext?
        
        public var nsPersistentContainer: NSPersistentContainer!
        
        public init(
            runtime: _SwiftDB_Runtime,
            schema: DatabaseSchema?,
            configuration: Configuration,
            state: State?
        ) throws {
            self.runtime = runtime
            self.schema = try schema.unwrap()
            self.configuration = configuration
            self.state = state ?? .init()
            
            if self.state.lastKnownSchema == nil {
                self.state.lastKnownSchema = schema
            }
            
            try createFoldersIfNecessary()
                        
            self.nsPersistentContainer = .init(
                name: configuration.name,
                managedObjectModel: try schema.map({ try .init($0) })
            )
            
            Task { @MainActor in
                try await loadPersistentStoresIfNeeded()
            }
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
            try await setupPersistentStoreDescription()
            
            guard nsPersistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else {
                return
            }

            try createFoldersIfNecessary()

            try await nsPersistentContainer.loadPersistentStores()
            
            nsPersistentContainer.persistentStoreCoordinator._SwiftDB_databaseSchema = self.schema
            nsPersistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            
            viewContext = DatabaseRecordContext(
                parent: self,
                managedObjectContext: self.nsPersistentContainer.viewContext,
                affectedStores: nil
            )
            
            objectWillChange.send()
        }
        
        private func setupPersistentStoreDescription() async throws {
            guard nsPersistentContainer.persistentStoreDescriptions.isEmpty else {
                return
            }
            
            if let sqliteStoreURL = sqliteStoreURL {
                let storeDescription = NSPersistentStoreDescription(url: sqliteStoreURL)
                
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
}

// MARK: - Conformances -

extension _CoreData.Database {
    public var capabilities: [DatabaseCapability] {
        []
    }
    
    @discardableResult
    public func fetchAllAvailableZones() -> AnyTask<[Zone], Error> {
        return Task {
            try await loadPersistentStoresIfNeeded()
            
            return nsPersistentContainer
                .persistentStoreCoordinator
                .persistentStores
                .map({ _CoreData.Database.Zone(persistentStore: $0) })
        }
        .convertToObservableTask()
    }
    
    @discardableResult
    public func fetchAllAvailableZones() async throws -> [Zone] {
        try await fetchAllAvailableZones().value
    }
    
    public func fetchZone(named name: String) -> AnyTask<Zone, Error> {
        fetchAllAvailableZones()
            .successPublisher
            .tryMap({ try $0.filter({ $0.name == name }).first.unwrap() })
            .eraseError()
            .convertToTask()
    }
    
    public func recordContext(forZones zones: [Zone]?) throws -> RecordContext {
        .init(
            parent: self,
            managedObjectContext: nsPersistentContainer.viewContext,
            affectedStores: zones?.map({ $0.persistentStore })
        )
    }
    
    public func delete() -> AnyTask<Void, Error> {
        return Task { @MainActor in
            await MainActor.run {
                objectWillChange.send()
            }
            
            self.viewContext = nil
            
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
    
    public func delete() async throws {
        try await delete().value
    }
    
    private func deleteAllStoreFiles() throws {
        let allStoreFiles = self.allStoreFiles
        
        try allStoreFiles.forEach { url in
            if FileManager.default.fileExists(at: url) {
                try FileManager.default.removeItem(at: url)
            }
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

// MARK: - Auxiliary Implementation -

extension _CoreData.Database {
    public var sqliteStoreURL: URL? {
        if let location = configuration.location {
            return location
        } else {
            guard let applicationGroupID = configuration.applicationGroupID else {
                return nsPersistentContainer.persistentStoreDescriptions.first?.url
            }
            
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupID)!.appendingPathComponent(nsPersistentContainer.name + ".sqlite")
        }
    }
    
    public var allStoreFiles: [URL] {
        var result: [URL] = []
        
        if let sqliteStoreURL = sqliteStoreURL {
            result.append(sqliteStoreURL.deletingLastPathComponent().appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist"))
            result.append(sqliteStoreURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            result.append(sqliteStoreURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            result.append(sqliteStoreURL.deletingLastPathComponent().appendingPathComponent(".\(nsPersistentContainer.name)_SUPPORT/"))
            result.append(sqliteStoreURL)
        }
        
        return result
    }
}
