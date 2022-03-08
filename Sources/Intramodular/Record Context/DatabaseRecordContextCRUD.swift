//
// Copyright (c) Vatsal Manot
//

import API
import Swallow
import FoundationX

extension DatabaseRecordContext {
    /// Create an entity instance.
    @discardableResult
    public func create<Instance: Entity>(_ type: Instance.Type) throws -> Instance {
        let record = try self.createRecord(
            withConfiguration: .init(
                recordType: try RecordType(type.name).unwrap(),
                recordID: nil,
                zone: nil
            ),
            context: .init()
        )
        
        return try instantiate(type, from: record)
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
    
    public func delete<Instance: Entity>(_ instance: Instance) async throws {
        try delete(getUnderlyingRecord(from: instance))
    }
}
