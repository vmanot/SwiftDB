//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

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
/// - RecordSpace:
///     An in-memory scratchpad for transacting on managed records.
public protocol Database: Named, Identifiable, Sendable where ID: Codable {
    typealias Runtime = _SwiftDB_Runtime
    
    associatedtype Configuration: Codable
    associatedtype State: Codable & Equatable
    associatedtype SchemaAdaptor: DatabaseSchemaAdaptor where SchemaAdaptor.Database == Self
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype TransactionExecutor: DatabaseTransactionExecutor
    associatedtype QuerySubscription: DatabaseQuerySubscription where QuerySubscription.Database == Self
    associatedtype RecordSpace: DatabaseRecordSpace where RecordSpace.Zone == Zone, RecordSpace.Record == Record

    typealias Transaction = TransactionExecutor.Transaction
    typealias Context = DatabaseContext<Self>
    typealias ZoneQueryRequest = DatabaseZoneQueryRequest<Self>
    
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
    
    func querySubscription(for request: ZoneQueryRequest) throws -> QuerySubscription

    func transactionExecutor() throws -> TransactionExecutor
}

// MARK: - Extensions

extension Database {
    public init(
        schema: _Schema?,
        configuration: Configuration,
        state: State?
    ) async throws {
        try await self.init(
            runtime: _SwiftDB_DefaultRuntime(schema: schema),
            schema: schema,
            configuration: configuration,
            state: state
        )
    }
}

extension Database {
    public func fetchAllAvailableZones() async throws -> [Zone] {
        try await fetchAllAvailableZones().value
    }
}
