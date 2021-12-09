//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow
import SwiftUI

public struct DatabaseRecordRelationshipDereferenceRequest<Context: DatabaseRecordContext> {
    public let recordID: Context.RecordID
    public let key: AnyStringKey
}

public protocol _opaque_DatabaseRecordContext: _opaque_ObservableObject {
    func execute<Model>(_ request: QueryRequest<Model>) -> AnyTask<QueryRequest<Model>.Output, Error>
}

public protocol DatabaseRecordContext: _opaque_DatabaseRecordContext, ObservableObject {
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    associatedtype RecordID: Hashable
    associatedtype RecordConfiguration = DatabaseRecordConfiguration<Self>
    
    typealias RecordCreateContext = DatabaseRecordCreateContext<Self>
    typealias ZoneQueryRequest = DatabaseZoneQueryRequest<Self>
    typealias SaveError = DatabaseRecordContextSaveError<Self>
    
    func createRecord(
        withConfiguration _: DatabaseRecordConfiguration<Self>,
        context: RecordCreateContext
    ) throws -> Record
    
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
    public func execute<Model>(_ request: QueryRequest<Model>) -> AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try execute(zoneQueryRequest(from: request))
                .successPublisher
                .tryMap { result in
                    QueryRequest<Model>.Output(
                        results: try (result.records ?? []).map { record in
                            try cast(cast(Model.self, to: _opaque_Entity.Type.self).init(_underlyingDatabaseRecord: record), to: Model.self) // FIXME: Refactor
                        }
                    )
                }
                .convertToTask()
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Auxiliary Implementation -

extension EnvironmentValues {
    struct _DatabaseRecordContextKey: EnvironmentKey {
        static let defaultValue: _opaque_DatabaseRecordContext? = nil
    }
    
    var _databaseRecordContext: _opaque_DatabaseRecordContext? {
        get {
            self[_DatabaseRecordContextKey.self]
        } set {
            self[_DatabaseRecordContextKey.self] = newValue
        }
    }
}
