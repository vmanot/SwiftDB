//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import CoreData
import Merge
import Swallow
import SwiftUIX

/// An opaque mirror for `DatabaseContainer`.
protocol _opaque_DatabaseContainer: _opaque_ObservableObject {
    var mainContext: AnyDatabaseRecordContext { get throws }
    
    func load() async throws
    func save() async throws
    
    func fetchAllInstances() async throws -> [Any]
    func reset() async throws
}

/// A type-erased database container.
///
/// Use this type to propagate a reference to your database container in your SwiftUI hierarchy.
public class AnyDatabaseContainer: _opaque_DatabaseContainer, CustomReflectable, Loggable, ObservableObject, @unchecked Sendable {
    public enum Status: String, CustomStringConvertible {
        case uninitialized
        case initialized
        case migrationRequired
        
        public var description: String {
            rawValue
        }
    }
    
    public var mainContext: AnyDatabaseRecordContext {
        get throws {
            fatalError(reason: .abstract)
        }
    }
    
    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
    
    @Published fileprivate(set) public var status: Status = .uninitialized
    
    public func load() async throws {
        fatalError(reason: .abstract)
    }
    
    public func save() async throws {
        fatalError(reason: .abstract)
    }
    
    public func fetchAllInstances() async throws -> [Any] {
        fatalError(reason: .abstract)
    }
    
    public func reset() async throws {
        fatalError(reason: .abstract)
    }
}

/// A container that encapsulates a database stack in your app.
public final class DatabaseContainer<Schema: SwiftDB.Schema>: AnyDatabaseContainer {
    public let cancellables = Cancellables()
    
    public let name: String
    public let schema: DatabaseSchema
    
    fileprivate let fileManager = FileManager.default
    
    fileprivate let location: URL?
    fileprivate let stateLocation: URL?
    fileprivate let applicationGroupID: String?
    fileprivate let cloudKitContainerIdentifier: String?
    
    fileprivate var database: _CoreData.Database!
    
    override public var mainContext: AnyDatabaseRecordContext {
        get throws {
            try database.viewContext.map(AnyDatabaseRecordContext.init).unwrap()
        }
    }
    
    public override var customMirror: Mirror {
        Mirror(self, children: [
            "status": status,
            "name": name,
            "schema": schema,
            "location": location as Any,
            "stateLocation": stateLocation as Any,
            "applicationGroupID": applicationGroupID as Any,
            "cloudKitContainerIdentifier": cloudKitContainerIdentifier as Any
        ])
    }
    
    enum Ops: LoggableOperation {
        case readAndRestoreDatabaseState
    }
    
    public init(
        name: String,
        schema: Schema,
        location: URL? = nil,
        applicationGroupID: String? = nil,
        cloudKitContainerIdentifier: String? = nil
    ) throws {
        self.name = name
        self.schema = try DatabaseSchema(schema)
        self.location = location
        self.stateLocation = location?.deletingLastPathComponent().appendingPathComponent(name, conformingTo: .fileURL).appendingPathExtension(DatabaseStateFileFormat.pathExtension)
        self.applicationGroupID = applicationGroupID
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        
        var existingDBState: _CoreData.Database.State?
        
        super.init()
        
        logger.dumpToConsole = true
        
        if let stateLocation = stateLocation, FileManager.default.fileExists(at: stateLocation) {
            _ = try? logger.log(Ops.readAndRestoreDatabaseState) {
                existingDBState = try JSONDecoder().decode(_CoreData.Database.State.self, from: Data(contentsOf: stateLocation))
            }
        }
        
        self.database = try _CoreData.Database(
            schema: .init(schema),
            configuration: _CoreData.Database.Configuration(
                name: name,
                location: location,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: existingDBState
        )
        
        if existingDBState == nil {
            saveState()
        }
    }
    
    public convenience init(name: String, schema: Schema) throws {
        try self.init(
            name: name,
            schema: schema,
            applicationGroupID: nil,
            cloudKitContainerIdentifier: nil
        )
    }
    
    @MainActor
    override public func load() async throws {
        do {
            guard status != .initialized else {
                return
            }
            
            do {
                try await performMigrationCheck()
                
                saveState()
            } catch {
                print(error)
            }
            
            _ = try await database.fetchAllAvailableZones()
            
            let mainContext = try? self.mainContext
            
            assert(mainContext != nil)
            
            status = .initialized
        } catch {
            logger.error(error)
            
            throw error
        }
    }
    
    @MainActor
    private func performMigrationCheck() async throws {
        let migrationCheck = try await database.performMigrationCheck()
        
        guard migrationCheck.zonesToMigrate.isEmpty else {
            status = .migrationRequired
            
            return
        }
    }
    
    override public func save() async throws {
        try await database
            .recordContext(forZones: nil)
            .save()
        
        saveState()
    }
    
    private func saveState() {
        Task.detached(priority: .userInitiated) { @MainActor in
            if let stateLocation = self.stateLocation {
                try JSONEncoder().encode(self.database.state).write(to: stateLocation)
            }
        }
        .logger(logger)
    }
    
    override public func fetchAllInstances() async throws -> [Any] {
        var result: [_opaque_Entity] = []
        
        for (name, type) in schema.entityNameToTypeMap {
            let instances = try! database.nsPersistentContainer.viewContext
                .fetch(NSFetchRequest<NSManagedObject>(entityName: name))
                .map {
                    try type.value.init(
                        _underlyingDatabaseRecord: _CoreData.DatabaseRecord(rawObject: $0)
                    )
                }
            
            result.append(contentsOf: instances)
        }
        
        return result
    }
    
    @MainActor
    override public func reset() async throws {
        objectWillChange.send()
        
        try await database.delete()
        
        database = try _CoreData.Database(
            schema: database.schema,
            configuration: _CoreData.Database.Configuration(
                name: name,
                location: location,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: .init()
        )
    }
}


// MARK: - Auxiliary Implementation -

extension CodingUserInfoKey {
    fileprivate static let _SwiftDB_PersistentContainer = CodingUserInfoKey(rawValue: "_SwiftDB_PersistentContainer")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_PersistentContainer: _opaque_DatabaseContainer! {
        get {
            self[._SwiftDB_PersistentContainer] as? _opaque_DatabaseContainer
        } set {
            self[._SwiftDB_PersistentContainer] = newValue
        }
    }
}
