//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import CoreData
import Merge
import Swallow
import SwiftUIX

/// A container that encapsulates a database stack in your app.
public final class LocalDatabaseContainer<Schema: SwiftDB.Schema>: AnyDatabaseContainer {
    private enum Tasks: Hashable, Sendable {
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
            guard status != .initialized else {
                return
            }
            
            do {
                assert(status != .initializing)
                
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
                
                liveAccess.setBase(AnyDatabase(erasing: database))
                
                
                do {
                    try await performMigrationCheck(database: database)
                    
                    saveState(database: database)
                    
                    _ = try await database.fetchAllAvailableZones()
                    
                    status = .initialized
                } catch {
                    status = .migrationCheckFailed
                }
            } catch {
                logger.error(error)
                
                throw error
            }
        }
    }
    
    public override func transact<R>(
        _ body: @escaping (AnyLocalTransaction) throws -> R
    ) async throws -> R {
        let database = try await loadedDatabase()
        let executor = try database.transactionExecutor()
        
        return try await executor.execute { transaction in
            let localTransaction = AnyLocalTransaction(
                transaction: .init(erasing: transaction),
                _SwiftDB_taskContext: .defaultContext(for: database)
            )
            
            return try body(localTransaction)
            
        }
    }
    
    public func querySubscription<T>(
        for queryRequest: QueryRequest<T>
    ) async throws -> QuerySubscription<T> {
        let database = try await loadedDatabase()
        
        return try AnyDatabase(erasing: database).querySubscription(for: queryRequest)
    }
    
    @MainActor
    override public func reset() async throws {
        let database = try await loadedDatabase()
        
        objectWillChange.send()
        
        try await database.delete().value
        
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

extension LocalDatabaseContainer {
    @MainActor
    private func loadedDatabase() async throws -> _CoreData.Database {
        guard status == .initialized else {
            throw Error.containerUninitialized
        }
        
        return try database.unwrap()
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

// MARK: - Auxiliary

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
