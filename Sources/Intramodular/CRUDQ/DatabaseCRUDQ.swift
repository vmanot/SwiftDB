//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Merge
import Swallow

public protocol DatabaseCRUDQ {
    func create<Instance: Entity>(_ entityType: Instance.Type) async throws -> Instance
    func queryExecutionTask<Model>(for request: QueryRequest<Model>) -> AnyTask<QueryRequest<Model>.Output, Error>
    func querySubscription<Model>(for request: QueryRequest<Model>) async throws -> QuerySubscription<Model>
    func delete<Instance: Entity>(_ instance: Instance) async throws
    func deleteAll() async throws
}

// MARK: - Extensions

extension DatabaseCRUDQ {
    /// Create an entity instance.
    @discardableResult
    public func create<Instance: Entity>(
        _ type: Instance.Type,
        body: (Instance) throws -> Void
    ) async throws -> Instance {
        let record = try await create(type)
        
        try body(record)
        
        return record
    }
}

extension DatabaseCRUDQ {
    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) async throws -> QueryRequest<Model>.Output {
        try await queryExecutionTask(for: request).value
    }
}

extension DatabaseCRUDQ {
    public func fetchAll() async throws -> [Any] {
        try await execute(
            QueryRequest<Any>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: nil,
                scope: nil
            )
        ).results
    }
    
    /// Fetch the first available entity instance.
    public func first<Instance: Entity>(
        _ type: Instance.Type
    ) async throws -> Instance? {
        try await execute(
            QueryRequest<Instance>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1),
                scope: nil
            )
        )
        .results.first
    }
    
    /// Fetch the first available entity instance.
    public func first<Instance: Entity>(
        _ type: Instance.Type = Instance.self,
        where predicate: CocoaPredicate<Instance>
    ) async throws -> Instance? {
        try await execute(
            QueryRequest<Instance>(
                predicate: predicate,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1),
                scope: nil
            )
        )
        .results.first
    }
    
    public func all<Instance: Entity>(
        of type: Instance.Type
    ) async throws -> [Instance] {
        try await execute(
            QueryRequest<Instance>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1),
                scope: nil
            )
        )
        .results
    }
}

extension DatabaseCRUDQ {
    public func delete<Instances: Sequence>(
        allOf instances: Instances
    ) async throws where Instances.Element: Entity {
        for instance in instances {
            try await delete(instance)
        }
    }
}
