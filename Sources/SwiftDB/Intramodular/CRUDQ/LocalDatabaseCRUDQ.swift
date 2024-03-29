//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import SwiftAPI

public protocol LocalDatabaseCRUDQ {
    func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance
    
    func execute<Model>(
        _ request: QueryRequest<Model>
    ) throws -> QueryRequest<Model>.Output
    
    func delete<Instance: Entity>(_ instance: Instance) throws
}

extension LocalDatabaseCRUDQ {
    public func fetchAll() throws -> [any Entity] {
        try execute(
            QueryRequest<any Entity>(
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
    ) throws -> Instance? {
        try execute(
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
    ) throws -> Instance? {
        try execute(
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
    ) throws -> [Instance] {
        try execute(
            QueryRequest<Instance>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1),
                scope: nil
            )
        )
        .results
    }
    
    public func deleteAll() throws {
        try fetchAll().forEach({ try delete($0) })
    }
}
