//
// Copyright (c) Vatsal Manot
//

import API
import Swallow

extension DatabaseCRUDQ {
    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) async throws -> QueryRequest<Model>.Output {
        try await queryExecutionTask(for: request).value
    }
}

extension DatabaseCRUDQ {
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
