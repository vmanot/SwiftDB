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
        case initializing
        case initialized
        case deinitializing
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
    private enum Tasks: Hashable {
        case initialize
        case load
    }
    
    private let taskGraph = TaskGraph<Tasks>()
    
    public let cancellables = Cancellables()
    
    public let name: String
    public let schema: _Schema
    
    fileprivate let fileManager = FileManager.default
    fileprivate let location: URL?
    fileprivate var stateLocation: URL? {
        location?.deletingLastPathComponent().appendingPathComponent(name, conformingTo: .fileURL).appendingPathExtension(DatabaseStateFileFormat.pathExtension)
    }
    
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
            "stateLocation": stateLocation as Any
        ])
    }
    
    enum Ops: LoggableOperation {
        case readAndRestoreDatabaseState
    }
    
    public init(
        name: String,
        schema: Schema,
        location: URL?
    ) throws {
        self.name = name
        self.schema = try _Schema(schema)
        self.location = location
        
        super.init()
        
        logger.dumpToConsole = true
    }
    
    @MainActor
    private func initializedDatabase() async throws -> _CoreData.Database {
        try await taskGraph.insert(.initialize, policy: .useExisting) { [self] in
            if let database = self.database {
                assert(status == .initialized)
                
                return database
            } else {
                assert(status != .initialized || status != .initializing)
                
                status = .initializing
                
                var existingDBState: _CoreData.Database.State?
                
                if let stateLocation = stateLocation, FileManager.default.fileExists(at: stateLocation) {
                    _ = try? logger.log(Ops.readAndRestoreDatabaseState) {
                        existingDBState = try JSONDecoder().decode(_CoreData.Database.State.self, from: Data(contentsOf: stateLocation))
                    }
                }
                
                logger.info("Initializing database at location: \(location.map(String.init(describing:)) ?? "null")")
                
                let database = try await _CoreData.Database(
                    schema: .init(schema),
                    configuration: _CoreData.Database.Configuration(
                        name: name,
                        location: location,
                        cloudKitContainerIdentifier: nil
                    ),
                    state: existingDBState
                )
                
                if existingDBState == nil {
                    self.saveState(database: database)
                }
                
                self.database = database
                
                status = .initialized
                
                return database
            }
        }
    }
    
    @MainActor
    override public func load() async throws {
        try await taskGraph.insert(.load, policy: .useExisting) {
            do {
                let database = try await initializedDatabase()
                
                do {
                    try await performMigrationCheck()
                    
                    saveState(database: database)
                } catch {
                    status = .migrationCheckFailed
                }
                
                _ = try await database.fetchAllAvailableZones()
                
                guard let mainContext = mainContext else {
                    status = .uninitialized
                    
                    return assertionFailure()
                }
                
                _mainAccess.base = _AnyDatabaseRecordContextTransaction(
                    databaseContext: database.context.eraseToAnyDatabaseContext(),
                    recordContext: mainContext
                )
            } catch {
                logger.error(error)
                
                throw error
            }
        }
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
                cloudKitContainerIdentifier: nil
            ),
            state: .init()
        )
    }
    
    // MARK: - Internal -
    
    @MainActor
    private func performMigrationCheck() async throws {
        do {
            let database = try await initializedDatabase()
            
            guard !database.state.schemaHistory.schemas.isEmpty else {
                logger.info("Schema history is empty. Skipping migration check.")
                
                return
            }
            
            let migrationCheck = try await initializedDatabase().performMigrationCheck()
            
            guard migrationCheck.zonesToMigrate.isEmpty else {
                status = .migrationRequired
                
                return
            }
        } catch {
            logger.error(error)
            
            status = .migrationCheckFailed
        }
    }
    
    private func saveState(database: _CoreData.Database) {
        guard let location = stateLocation else {
            return
        }
        
        Task.detached(priority: .userInitiated) { @MainActor in
            SaveDatabaseState(
                state: database.state,
                location: location
            )
        }
        .logger(logger)
    }
}

// MARK: - Initializers -

extension DatabaseContainer {
    public convenience init(name: String, schema: Schema) throws {
        try self.init(
            name: name,
            schema: schema,
            location: nil
        )
    }
    
    public convenience init(
        name: String,
        schema: Schema,
        location: CanonicalFileDirectory,
        sqliteFilePath: String
    ) throws {
        try self.init(
            name: name,
            schema: schema,
            location: location.toURL().appendingPathComponent(sqliteFilePath)
        )
    }
}

// MARK: - Operations -

extension AnyDatabaseContainer {
    struct SaveDatabaseState {
        let state: _CoreData.Database.State
        let location: URL
        
        func callAsFunction() async throws {
            try JSONEncoder().encode(state).write(to: location)
        }
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
