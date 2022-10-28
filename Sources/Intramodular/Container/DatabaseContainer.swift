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
    
    public private(set) var liveAccess = LiveAccess()
    
    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
    
    @Published fileprivate(set) public var status: Status = .uninitialized
    
    public func load() async throws {
        fatalError(reason: .abstract)
    }
    
    public func transact<R>(
        _ body: (DatabaseCRUDQ) async throws -> R
    ) async throws -> R {
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
    
    private var mainContext: AnyDatabaseRecordSpace? {
        database?.viewContext.map(AnyDatabaseRecordSpace.init)
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
    override public func load() async throws {
        try await taskGraph.insert(.load, policy: .useExisting) {
            do {
                let database = try await initializeDatabase()
                
                do {
                    try await performMigrationCheck(database: database)
                    
                    saveState(database: database)
                } catch {
                    status = .migrationCheckFailed
                }
                
                _ = try await database.fetchAllAvailableZones()
                
                guard let mainContext = mainContext else {
                    status = .uninitialized
                    
                    return assertionFailure()
                }
                
                liveAccess.setBaseTransaction(
                    _AnyRecordSpaceTransaction(
                        databaseContext: database.context.eraseToAnyDatabaseContext(),
                        recordSpace: mainContext
                    )
                )
            } catch {
                logger.error(error)
                
                throw error
            }
        }
    }
    
    @MainActor
    public override func transact<R>(
        _ body: (DatabaseCRUDQ) async throws -> R
    ) async throws -> R {
        let database = try await loadedDatabase()
        
        let transaction = _AnyRecordSpaceTransaction(
            databaseContext: database.context.eraseToAnyDatabaseContext(),
            recordSpace: .init(erasing: try database.viewContext.unwrap())
        )
        
        let result: R
        
        do {
            result = try await body(transaction)
        } catch {
            assertionFailure(error)
            
            throw error
        }
        
        try await transaction.commit()
        
        return result
    }
    
    @MainActor
    override public func reset() async throws {
        let database = try await loadedDatabase()
        
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
}

// MARK: - Internal -

extension DatabaseContainer {
    @MainActor
    private func loadedDatabase() async throws -> _CoreData.Database {
        guard status == .initialized else {
            throw Error.containerUninitialized
        }
        
        return try database.unwrap()
    }
    
    @MainActor
    private func initializeDatabase() async throws -> _CoreData.Database {
        try await taskGraph.insert(.initialize, policy: .useExisting) { [self] in
            if let database = self.database {
                assert(status == .initialized)
                
                return database
            } else {
                assert(status != .initialized || status != .initializing)
                
                status = .initializing
                
                var existingDBState: _CoreData.Database.State?
                
                if let stateLocation = stateLocation, FileManager.default.fileExists(at: stateLocation) {
                    existingDBState = try JSONDecoder().decode(_CoreData.Database.State.self, from: Data(contentsOf: stateLocation))
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
    private func performMigrationCheck(database: _CoreData.Database) async throws {
        do {
            guard !database.state.schemaHistory.schemas.isEmpty else {
                logger.info("Schema history is empty. Skipping migration check.")
                
                return
            }
            
            let migrationCheck = try await database.performMigrationCheck()
            
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

// MARK: - Auxiliary Implementation -

extension AnyDatabaseContainer {
    public enum Error: Swift.Error {
        case containerUninitialized
    }
}

extension AnyDatabaseContainer {
    struct SaveDatabaseState {
        let state: _CoreData.Database.State
        let location: URL
        
        func callAsFunction() async throws {
            try JSONEncoder().encode(state).write(to: location)
        }
    }
}
