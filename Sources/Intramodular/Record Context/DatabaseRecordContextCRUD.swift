//
// Copyright (c) Vatsal Manot
//

import Swallow

extension DatabaseRecordContext {
    @discardableResult
    public func create<Instance: Entity>(_ type: Instance.Type) throws -> Instance {
        try type.init(
            underlyingRecord: try self.createRecord(
                withConfiguration: .init(
                    recordType: try RecordType(type.name).unwrap(),
                    recordID: nil,
                    zone: nil
                ),
                context: .init()
            ),
            recordContext: self
        )
    }

    public func first<Instance: Entity>(
        _ type: Instance.Type
    ) async throws -> Instance? {
        try await execute(
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
        .successPublisher
        .tryMap({ try $0.records.unwrap().first.unwrap() })
        .tryMap({ try self.instantiate(type, from: $0) })
        .output()
    }

    public func delete<Instance: Entity>(_ instance: Instance) async throws {
        try await _opaque_delete(instance)
    }

    func _opaque_delete(_ instance: _opaque_Entity) async throws {
        let _record = try instance._underlyingDatabaseRecord.unwrap()
        let record = try cast(_record, to: Record.self)

        try delete(record)

        _ = try await save()
    }
}
