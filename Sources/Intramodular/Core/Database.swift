//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public struct DatabaseContext<Database: SwiftDB.Database> {
    public let runtime: _SwiftDB_Runtime
    public let schema: _Schema
    public let schemaAdaptor: Database.SchemaAdaptor
    
    public init(
        runtime: _SwiftDB_Runtime,
        schema: _Schema,
        schemaAdaptor: Database.SchemaAdaptor
    ) {
        self.runtime = runtime
        self.schema = schema
        self.schemaAdaptor = schemaAdaptor
    }
        
    public func eraseToAnyDatabaseContext() -> DatabaseContext<AnyDatabase> {
        .init(
            runtime: runtime,
            schema: schema,
            schemaAdaptor: .init(erasing: schemaAdaptor)
        )
    }
    
    public func recordSchema(
        forRecordType recordType: Database.RecordContext.RecordType
    ) throws -> _Schema.Record? {
        guard let recordSchemaID = try schemaAdaptor.entity(forRecordType: recordType) else {
            return nil
        }
        
        return schema[recordSchemaID]
    }
}

/// A type that represents a database.
///
/// A SwiftDB database is made up of the following parts:
///
/// - Configuration:
///     The configuration that initializes the database.
/// - SchemaAdaptor:
///     An adaptor provided by the database to convert SwiftDB schemas to its own schema representation.
/// - State:
///     An encapsulation of any additional metadata stored by the database.
/// - Zone:
///     A representation of a local or remote store.
/// - RecordContext:
///     An in-memory scratchpad for transacting on managed records.
public protocol Database: Named, Identifiable where ID: Codable {
    typealias Runtime = _SwiftDB_Runtime
    
    associatedtype Configuration: Codable
    associatedtype State: Codable & Equatable
    associatedtype SchemaAdaptor: DatabaseSchemaAdaptor where SchemaAdaptor.Database == Self
    associatedtype Zone where Zone == RecordContext.Zone
    associatedtype RecordContext: DatabaseRecordContext
    
    typealias Context = DatabaseContext<Self>
    
    /// The configuration used to initialize the database.
    var configuration: Configuration { get }
        
    /// A type that encapsulates the database state and additional metadata.
    var state: State { get }

    /// The database context.
    var context: Context { get }
    
    init(
        runtime: _SwiftDB_Runtime,
        schema: _Schema?,
        configuration: Configuration,
        state: State?
    ) async throws
    
    @discardableResult
    func fetchAllAvailableZones() -> AnyTask<[Zone], Error>
    @discardableResult
    func fetchZone(named _: String) -> AnyTask<Zone, Error>
    
    func recordContext(forZones _: [Zone]?) throws -> RecordContext
    
    /// Erase all data in the database.
    ///
    /// This operation is always an atomic operation.
    func delete() -> AnyTask<Void, Error>
}

// MARK: - Extensions -

extension Database {
    public init(
        schema: _Schema?,
        configuration: Configuration,
        state: State?
    ) async throws {
        try await self.init(
            runtime: _Default_SwiftDB_Runtime(schema: schema),
            schema: schema,
            configuration: configuration,
            state: state
        )
    }
}
