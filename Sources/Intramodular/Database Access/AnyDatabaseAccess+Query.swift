//
// Copyright (c) Vatsal Manot
//

import API
import Diagnostics
import Merge
import Swallow

extension AnyDatabaseAccess {
    public func _convertToEntityInstance(_ record: AnyDatabaseRecord) throws -> any Entity {
        let schema = try databaseContext.schema
        let entityID = try databaseContext.schemaAdaptor.entity(forRecordType: record.recordType).unwrap()
        
        return try! schema.entityType(for: entityID).init(from: record)
    }
    
    public func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try recordContext.execute(zoneQueryRequest(from: request))
                .successPublisher
                .tryMap { result in
                    QueryRequest<Model>.Output(
                        results: try (result.records ?? []).map { record in
                            try cast(_convertToEntityInstance(record), to: Model.self)
                        }
                    )
                }
                .convertToTask()
        } catch {
            return .failure(error)
        }
    }
    
    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) async throws -> QueryRequest<Model>.Output {
        try await queryExecutionTask(for: request).value
    }
    
    /// Translate a `QueryRequest` into a zone query request for this record context.
    ///
    /// - Parameters:
    ///   - queryRequest: The query request to translate.
    public func zoneQueryRequest<Model>(
        from queryRequest: QueryRequest<Model>
    ) throws -> AnyDatabaseRecordContext.ZoneQueryRequest {
        let recordTypes: [AnyDatabaseRecord.RecordType]
        
        if Model.self == Any.Type.self {
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

extension AnyDatabaseAccess {
    public func fetchAllInstances() async throws -> [Any] {
        try await execute(QueryRequest<Any>(predicate: nil, sortDescriptors: nil, fetchLimit: nil)).results
    }

    /// Fetch the first available entity instance.
    public func first<Instance: Entity>(
        _ type: Instance.Type
    ) async throws -> Instance? {
        try await execute(
            QueryRequest<Instance>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1)
            )
        )
        .results.first
    }
    
    /// Fetch the first available entity instance.
    public func first<Instance: Entity>(
        _ type: Instance.Type = Instance.self,
        where predicate: Predicate<Instance>
    ) async throws -> Instance? {
        try await execute(
            QueryRequest<Instance>(
                predicate: predicate,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1)
            )
        )
        .results.first
    }
    
    public func all<Instance: Entity>(of type: Instance.Type) async throws -> [Instance] {
        try await execute(
            QueryRequest<Instance>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1)
            )
        )
        .results
    }
}
