//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct AnyDatabaseTransaction: DatabaseTransaction {
    public typealias Database = AnyDatabase

    private let base: any DatabaseTransaction

    public init<Transaction: DatabaseTransaction>(erasing base: Transaction) {
        self.base = base
    }

    public func createRecord(
        withConfiguration configuration: RecordConfiguration
    ) throws -> Database.Record {
        try base._opaque_createRecord(withConfiguration: configuration)
    }

    public func executeSynchronously(
        _ request: AnyDatabase.ZoneQueryRequest
    ) throws -> AnyDatabase.ZoneQueryRequest.Result {
        try base._opaque_executeSynchronously(request)
    }

    public func delete(_ record: Database.Record) throws {
        try base._opaque_delete(record)
    }
}

fileprivate extension DatabaseTransaction {
    func _opaque_createRecord(
        withConfiguration configuration: AnyDatabaseTransaction.RecordConfiguration
    ) throws -> AnyDatabase.Record {
        assert(!(self is AnyDatabaseTransaction))

        let record = try createRecord(
            withConfiguration: .init(
                recordType: configuration.recordType?._cast(to: Database.Record.RecordType.self),
                recordID: configuration.recordID.map({ try $0._cast(to: Database.Record.ID.self) }),
                zone: configuration.zone.map({ try cast($0.base, to: Database.Zone.self) })
            )
        )

        return AnyDatabaseRecord(erasing: record)
    }

    func _opaque_executeSynchronously(
        _ request: AnyDatabase.ZoneQueryRequest
    ) throws -> AnyDatabase.ZoneQueryRequest.Result {
        assert(!(self is AnyDatabaseTransaction))

        return .init(_erasing: try executeSynchronously(try request._cast(to: Database.ZoneQueryRequest.self)))
    }

    func _opaque_delete(_ record: AnyDatabase.Record) throws {
        assert(!(self is AnyDatabaseTransaction))

        return try delete(record._cast(to: Database.Record.self))
    }
}
