//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import SwiftUI

public struct DatabaseRecordRelationshipDereferenceRequest<Context: DatabaseRecordContext> {
    public let recordID: Context.RecordID
    public let key: AnyStringKey
}

public protocol _opaque_DatabaseRecordContext: _opaque_ObservableObject {
    func execute<Model: Entity>(_ request: QueryRequest<Model>) -> AnyTask<QueryRequest<Model>.Output, Error>
}

/// An object space to manipulate and track changes to managed objects.
public protocol DatabaseRecordContext: _opaque_DatabaseRecordContext, ObservableObject {
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    associatedtype RecordID: Hashable
    associatedtype RecordConfiguration = DatabaseRecordConfiguration<Self>
    
    typealias RecordCreateContext = DatabaseRecordCreateContext<Self>
    typealias ZoneQueryRequest = DatabaseZoneQueryRequest<Self>
    typealias SaveError = DatabaseRecordContextSaveError<Self>

    /// Create a database record associated with this context.
    func createRecord(
        withConfiguration _: DatabaseRecordConfiguration<Self>,
        context: RecordCreateContext
    ) throws -> Record
    
    /// Instantiate a SwiftDB entity instance from a record.
    func instantiate<Instance: Entity>(_ type: Instance.Type, from record: Record) throws -> Instance
        
    /// Get the underlying database record from an entity instance.
    func getUnderlyingRecord<Instance: Entity>(from instance: Instance) throws -> Record
    
    /// Get the record ID associated with this record.
    func recordID(from record: Record) throws -> RecordID
    
    /// Get the zone associatdd with this record.
    func zone(for: Record) throws -> Zone?
    
    /// Mark a record for deletion in this record context.
    func delete(_: Record) throws
    
    /// Execute a zone query request within the zones captured by this record context.
    func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error>
    
    /// Save the changes made in this record context.
    func save() -> AnyTask<Void, SaveError>

    /// Translate a `QueryRequest` into a zone query request for this record context.
    func zoneQueryRequest<Model>(from queryRequest: QueryRequest<Model>) throws -> ZoneQueryRequest
}

// MARK: - Implementation -

extension DatabaseRecordContext {
    public func execute(_ request: ZoneQueryRequest) async throws -> ZoneQueryRequest.Result {
        try await execute(request).value
    }
    
    public func execute<Model: Entity>(
        _ request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try execute(zoneQueryRequest(from: request))
                .successPublisher
                .tryMap { result in
                    QueryRequest<Model>.Output(
                        results: try (result.records ?? []).map { record in
                            try self.instantiate(Model.self.self, from: record)
                        }
                    )
                }
                .convertToTask()
        } catch {
            return .failure(error)
        }
    }
    
    public func save() async throws {
        try await save().successPublisher.output()
    }
}

// MARK: - SwiftUI -

extension EnvironmentValues {
    fileprivate struct DatabaseRecordContextKey: EnvironmentKey {
        static let defaultValue: AnyDatabaseRecordContext = .invalid
    }
    
    public var databaseRecordContext: AnyDatabaseRecordContext {
        get {
            self[DatabaseRecordContextKey.self]
        } set {
            self[DatabaseRecordContextKey.self] = newValue
        }
    }
}

extension View {
    public func databaseRecordContext(_ context: AnyDatabaseRecordContext?) -> some View {
        environment(\.databaseRecordContext, context ?? .invalid)
    }
}
