//
// Copyright (c) Vatsal Manot
//

import API
import Diagnostics
import Merge
import Swallow

public final class _AnyDatabaseRecordContextTransaction: DatabaseTransaction {
    public let id: DatabaseTransactionID = .init(rawValue: UUID())
    
    private let databaseContext: AnyDatabase.Context
    private let recordContext: AnyDatabase.RecordContext
    
    public init(
        databaseContext: AnyDatabase.Context,
        recordContext: AnyDatabase.RecordContext
    ) {
        self.databaseContext = databaseContext
        self.recordContext = recordContext
    }
    
    public func commit() async throws {
        try await recordContext.save()
    }
    
    public func scope<T>(_ operation: (DatabaseTransactionContext) throws -> T) throws -> T {
        try withDatabaseTransactionContext(.init(databaseContext: databaseContext, transaction: self)) { context in
            try operation(context)
        }
    }
}

extension _AnyDatabaseRecordContextTransaction {
    public func willChangePublisher() -> AnyObjectWillChangePublisher {
        recordContext.objectWillChange
    }
}

extension _AnyDatabaseRecordContextTransaction {
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        return try scope { context in
            let entity = try self.databaseContext.schema.entity(forModelType: entityType).unwrap()
            
            let record = try self.recordContext.createRecord(
                withConfiguration: .init(
                    recordType: self.databaseContext.schemaAdaptor.recordType(for: entity.id),
                    recordID: nil,
                    zone: nil
                ),
                context: .init()
            )
            
            let recordContainer = _DatabaseRecordContainer(
                transactionContext: context,
                recordSchema: entity,
                record: record
            )
            
            return try entityType.init(from: recordContainer)
        }
    }
}

extension _AnyDatabaseRecordContextTransaction {
    public func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try scope { context in
                try recordContext
                    .execute(zoneQueryRequest(from: request))
                    .successPublisher
                    .tryMap { result in
                        QueryRequest<Model>.Output(
                            results: try (result.records ?? []).map { record in
                                try withDatabaseTransactionContext(context) { context in
                                    try cast(self._convertToEntityInstance(record), to: Model.self)
                                }
                            }
                        )
                    }
                    .convertToTask()
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func querySubscription<Model>(for request: QueryRequest<Model>) throws -> QuerySubscription<Model> {
        try .init(from: recordContext.querySubscription(for: zoneQueryRequest(from: request)))
    }
    
    private func _convertToEntityInstance(_ record: AnyDatabaseRecord) throws -> any Entity {
        try scope { context in
            let schema = databaseContext.schema
            let entityID = try databaseContext.schemaAdaptor.entity(forRecordType: record.recordType).unwrap()
            let entity = try databaseContext.schema[entityID].unwrap()
            
            let recordContainer = _DatabaseRecordContainer(
                transactionContext: context,
                recordSchema: entity,
                record: record
            )
            
            return try schema.entityType(for: entityID).init(from: recordContainer)
        }
    }
    
    private func zoneQueryRequest<Model>(
        from queryRequest: QueryRequest<Model>
    ) throws -> AnyDatabaseRecordContext.ZoneQueryRequest {
        let recordTypes: [AnyDatabaseRecord.RecordType]
        
        if Model.self == Any.self {
            recordTypes = try databaseContext.schema.entities.map({ try databaseContext.schemaAdaptor.recordType(for: $0.id) })
        } else {
            let entity = try databaseContext.schema.entity(forModelType: Model.self).unwrap().id
            
            recordTypes = [try databaseContext.schemaAdaptor.recordType(for: entity)]
        }
        
        return try AnyDatabaseRecordContext.ZoneQueryRequest(
            filters: .init(
                zones: nil,
                recordTypes: Set(recordTypes),
                includesSubentities: true
            ),
            predicate: queryRequest.predicate.map({ predicate in
                DatabaseZoneQueryPredicate(
                    try predicate.toNSPredicate(
                        context: .init(
                            expressionConversionContext: .init(
                                keyPathConversionStrategy: .custom(databaseContext.runtime.convertEntityKeyPathToString),
                                keyPathPrefix: nil
                            )
                        )
                    )
                )
            }),
            sortDescriptors: queryRequest.sortDescriptors,
            cursor: nil,
            limit: queryRequest.fetchLimit
        )
    }
}

extension _AnyDatabaseRecordContextTransaction {
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try recordContext.delete(AnyDatabaseRecord(from: instance))
    }
}
