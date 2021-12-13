//
// Copyright (c) Vatsal Manot
//

import CoreData
import Diagnostics
import Merge
import Swallow

extension _CoreData {
    public final class Database: CancellablesHolder, ObservableObject {
        private let logger = os.Logger(subsystem: "com.vmanot.SwiftDB", category: "_CoreData.Database")

        enum ConfigurationError: Error {
            case customLocationPathExtensionMissing
        }

        public struct Configuration: Codable {
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
        
        public struct State: Codable, ExpressibleByNilLiteral {
            public init(nilLiteral: Void) {
                
            }
        }
        
        let runtime: DatabaseRuntime
        let schema: DatabaseSchema
        
        public let configuration: Configuration
        public var state: State
        public var viewContext: DatabaseRecordContext?
        
        public let nsPersistentContainer: NSPersistentContainer
        
        public init(
            runtime: DatabaseRuntime,
            schema: DatabaseSchema?,
            configuration: Configuration,
            state: State
        ) throws {
            self.runtime = runtime
            self.schema = try schema.unwrap()
            self.configuration = configuration
            self.state = state

            if let location = configuration.location {
                guard location.pathExtension == "sqlite" else {
                    throw ConfigurationError.customLocationPathExtensionMissing
                }

                let locationContainer = location.deletingLastPathComponent()

                if !FileManager.default.directoryExists(at: locationContainer) {
                    try FileManager.default.createDirectory(at: locationContainer, withIntermediateDirectories: true, attributes: nil)
                }
            }

            if let schema = schema {
                self.nsPersistentContainer = .init(name: configuration.name, managedObjectModel: try .init(schema))
            } else {
                self.nsPersistentContainer = .init(name: configuration.name)
            }
            
            try loadPersistentStores()
        }
        
        public init(container: NSPersistentContainer, schema: DatabaseSchema) throws {
            self.runtime = _DefaultDatabaseRuntime()
            self.schema = schema
            self.configuration = .init(
                name: container.name,
                location: nil,
                applicationGroupID: nil,
                cloudKitContainerIdentifier: nil
            )
            self.state = nil
            self.nsPersistentContainer = container
            
            try loadPersistentStores()
        }
        
        private func setupPersistentStoreDescription() throws {
            if let sqliteStoreURL = sqliteStoreURL {
                nsPersistentContainer.persistentStoreDescriptions = [.init(url: sqliteStoreURL)]
            }
            
            let description = try nsPersistentContainer.persistentStoreDescriptions.first.unwrap()
            
            if let cloudKitContainerIdentifier = configuration.cloudKitContainerIdentifier {
                description.cloudKitContainerOptions = .init(containerIdentifier: cloudKitContainerIdentifier)
                
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }
        
        private func loadPersistentStores() throws {
            try setupPersistentStoreDescription()
            
            nsPersistentContainer
                .loadPersistentStores()
                .sinkResult({ result in
                    self.nsPersistentContainer.persistentStoreCoordinator._SwiftDB_databaseSchema = self.schema
                    
                    self.nsPersistentContainer
                        .viewContext
                        .automaticallyMergesChangesFromParent = true
                    
                    self.viewContext = DatabaseRecordContext(
                        parent: self,
                        managedObjectContext: self.nsPersistentContainer.viewContext,
                        affectedStores: nil
                    )
                    
                    self.objectWillChange.send()
                })
                .store(in: cancellables)
        }
    }
}

// MARK: - Conformances -

extension _CoreData.Database: Database {
    public typealias RecordContext = _CoreData.DatabaseRecordContext
    
    public var capabilities: [DatabaseCapability] {
        []
    }
    
    @discardableResult
    public func fetchAllAvailableZones() -> AnyTask<[Zone], Error> {
        if nsPersistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
            return nsPersistentContainer.loadPersistentStores().map {
                self.nsPersistentContainer
                    .persistentStoreCoordinator
                    .persistentStores
                    .map({ _CoreData.Database.Zone(persistentStore: $0) })
            }
            .convertToTask()
        } else {
            return .just(.success(nsPersistentContainer.persistentStoreCoordinator.persistentStores.map({ Zone(persistentStore: $0) })))
        }
    }
    
    public func fetchZone(named name: String) -> AnyTask<Zone, Error> {
        fetchAllAvailableZones()
            .successPublisher
            .tryMap({ try $0.filter({ $0.name == name }).first.unwrap() })
            .eraseError()
            .convertToTask()
    }
    
    public func recordContext(forZones zones: [Zone]?) throws -> RecordContext {
        .init(parent: self, managedObjectContext: nsPersistentContainer.viewContext, affectedStores: zones?.map({ $0.persistentStore }))
    }
    
    public func delete() -> AnyTask<Void, Error> {
        allStoreFiles.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
        
        return .just(.success(()))
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
