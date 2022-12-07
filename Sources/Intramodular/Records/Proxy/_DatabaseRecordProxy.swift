//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Merge
import Swallow

public protocol _DatabaseRecordProxyBase {
    var allKeys: [AnyCodingKey] { get }

    func containsValue(forKey key: AnyCodingKey) throws -> Bool

    func decode<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value
    func encode<Value>(_ value: Value, forKey key: AnyCodingKey) throws

    func unsafeDecodeValue(forKey key: AnyCodingKey) throws -> Any?
    func unsafeEncodeValue(_ payload: Any?, forKey key: AnyCodingKey) throws
}

/// A proxy to a record container OR snapshot.
public final class _DatabaseRecordProxy: CancellablesHolder {
    private enum OperationType {
        case read
        case write
    }

    public private(set) var base: _DatabaseRecordProxyBase

    public let recordID: AnyDatabaseRecord.ID

    private init(base: _DatabaseRecordProxyBase, recordID: AnyDatabaseRecord.ID) {
        self.base = base
        self.recordID = recordID
    }

    static func snapshot(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) throws -> Self {
        self.init(
            base: try _DatabaseRecordSnapshot(
                from: try _DatabaseRecordDataDecoder(
                    recordSchema: recordSchema,
                    record: record
                )
            ),
            recordID: record.id
        )
    }

    static func transactionScoped(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord,
        transaction: AnyDatabaseTransaction
    ) throws -> Self {
        self.init(
            base: try _TransactionScopedRecord(
                _SwiftDB_taskContext: _SwiftDB_taskContext,
                recordSchema: recordSchema,
                record: record,
                transaction: transaction
            ),
            recordID: record.id
        )
    }
}

extension _DatabaseRecordProxy {
    var allKeys: [AnyCodingKey] {
        base.allKeys
    }

    func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        try base.containsValue(forKey: key)
    }

    func decode<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }

    func encode<Value>(_ value: Value, forKey key: AnyCodingKey) throws {
        try base.encode(value, forKey: key)
    }

    func unsafeDecodeValue(forKey key: AnyCodingKey) throws -> Any? {
        try base.unsafeDecodeValue(forKey: key)
    }

    func unsafeEncodeValue(_ payload: Any?, forKey key: AnyCodingKey) throws {
        try base.unsafeEncodeValue(payload, forKey: key)
    }
}

extension _DatabaseRecordProxy {
    func decodeFieldPayload(forKey key: AnyCodingKey) throws -> _RecordFieldPayload? {
        try cast(base, to: _TransactionScopedRecord.self).decodeFieldPayload(forKey: key)
    }

    func primaryKeyOrRecordID() throws -> _RecordFieldPayload.PrimaryKeyOrRecordID {
        try cast(base, to: _TransactionScopedRecord.self).primaryKeyOrRecordID()
    }
}
