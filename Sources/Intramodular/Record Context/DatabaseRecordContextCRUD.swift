//
// Copyright (c) Vatsal Manot
//

import Swallow

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
        let result = try await execute(
            DatabaseZoneQueryRequest(
                filters: .init(
                    zones: nil,
                    recordTypes: [RecordType(type.name).unwrap()],
                    includesSubentities: true
                ),
                predicate: nil,
                sortDescriptors: nil,
                cursor: nil,
                limit: .cursor(.offset(1))
            )
        )

        guard let record = result.records?.first else {
            return nil
        }

        return try instantiate(type, from: record)
    }

    public func delete<Instance: Entity>(_ instance: Instance) async throws {
        try delete(getUnderlyingRecord(from: instance))
    }
}
