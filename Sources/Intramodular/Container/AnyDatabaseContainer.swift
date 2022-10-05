//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import CoreData
import Merge
import Swallow
import SwiftUIX

/// A type-erased database container.
///
/// Use this type to propagate a reference to your database container in your SwiftUI hierarchy.
public class AnyDatabaseContainer: CustomReflectable, Loggable, ObservableObject, @unchecked Sendable {
    public enum Status: String, CustomStringConvertible {
        case uninitialized
        case initialized
        case migrationCheckFailed
        case migrationRequired
        
        public var description: String {
            rawValue
        }
    }
    
    public var mainAccess: LiveDatabaseAccess {
        fatalError(reason: .abstract)
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
    public let schema: _Schema
    
    fileprivate let fileManager = FileManager.default
    
    fileprivate let location: URL?
    fileprivate let stateLocation: URL?
    fileprivate let applicationGroupID: String?
    fileprivate let cloudKitContainerIdentifier: String?
    
    fileprivate var initializeDatabaseTask: Task<_CoreData.Database, Error>?
    fileprivate var database: _CoreData.Database?
    
    private var mainContext: AnyDatabaseRecordContext? {
        database?.viewContext.map(AnyDatabaseRecordContext.init)
    }
    
    private var _mainAccess = LiveDatabaseAccess(base: nil)
    
    override public var mainAccess: LiveDatabaseAccess {
        _mainAccess
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
        self.schema = try _Schema(schema)
        self.location = location
        self.stateLocation = location?.deletingLastPathComponent().appendingPathComponent(name, conformingTo: .fileURL).appendingPathExtension(DatabaseStateFileFormat.pathExtension)
        self.applicationGroupID = applicationGroupID
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        
        super.init()
        
        logger.dumpToConsole = true
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
    private func initializedDatabase() async throws -> _CoreData.Database {
        if let database = self.database {
            return database
        }
        
        if let initializeDatabaseTask = initializeDatabaseTask {
            return try await initializeDatabaseTask.value
        } else {
            let task = Task { @MainActor in
                var existingDBState: _CoreData.Database.State?
                
                if let stateLocation = stateLocation, FileManager.default.fileExists(at: stateLocation) {
                    _ = try? logger.log(Ops.readAndRestoreDatabaseState) {
                        existingDBState = try JSONDecoder().decode(_CoreData.Database.State.self, from: Data(contentsOf: stateLocation))
                    }
                }
                
                let database = try await _CoreData.Database(
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
                    self.saveState()
                }
                
                self.database = database
                self.initializeDatabaseTask = nil
                
                return database
            }
            
            self.initializeDatabaseTask = task
            
            return try await task.value
        }
    }
    
    @MainActor
    override public func load() async throws {
        do {
            let database = try await initializedDatabase()
            
            guard status != .initialized else {
                return
            }
            
            do {
                try await performMigrationCheck()
                
                saveState()
            } catch {
                status = .migrationCheckFailed
            }
            
            _ = try await database.fetchAllAvailableZones()
            
            guard let mainContext = mainContext else {
                status = .uninitialized
                
                return assertionFailure()
            }
            
            _mainAccess.base = _AnyDatabaseRecordContextTransaction(
                databaseContext: mainContext.databaseContext,
                recordContext: mainContext
            )
            
            status = .initialized
        } catch {
            logger.error(error)
            
            throw error
        }
    }
    
    @MainActor
    private func performMigrationCheck() async throws {
        do {
            let migrationCheck = try await initializedDatabase().performMigrationCheck()
            
            guard migrationCheck.zonesToMigrate.isEmpty else {
                status = .migrationRequired
                
                return
            }
        } catch {
            status = .migrationRequired
        }
    }
    
    private func saveState() {
        Task.detached(priority: .userInitiated) { @MainActor in
            let database = try await self.initializedDatabase()
            
            if let stateLocation = self.stateLocation {
                try JSONEncoder().encode(database.state).write(to: stateLocation)
            }
        }
        .logger(logger)
    }
    
    @MainActor
    override public func reset() async throws {
        let database = try await initializedDatabase()
        
        objectWillChange.send()
        
        try await database.delete()
        
        self.database = try await _CoreData.Database(
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
    fileprivate static let _SwiftDB_DatabaseContainer = CodingUserInfoKey(rawValue: "_SwiftDB_DatabaseContainer")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_DatabaseContainer: AnyDatabaseContainer! {
        get {
            self[._SwiftDB_DatabaseContainer] as? AnyDatabaseContainer
        } set {
            self[._SwiftDB_DatabaseContainer] = newValue
        }
    }
}
