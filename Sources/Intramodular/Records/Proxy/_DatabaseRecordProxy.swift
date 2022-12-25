//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Merge
import Swallow

protocol _DatabaseRecordProxyBase {
    var allKeys: [AnyCodingKey] { get }
    
    func containsValue(forKey key: AnyCodingKey) throws -> Bool
    
    func decodeValue<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value
    func encodeValue<Value>(_ value: Value, forKey key: AnyCodingKey) throws
    func decodeValue(forKey key: AnyCodingKey) throws -> Any?
    func encodeValue(_ payload: Any?, forKey key: AnyCodingKey) throws
    
    func decodeRelationship(
        forKey _: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase>
    
    func encodeRelationship(
        _: RelatedDatabaseRecordIdentifiers<AnyDatabase>,
        forKey _: AnyCodingKey
    ) throws
    
    func encodeRelationshipDiff(
        _: RelatedDatabaseRecordIdentifiers<AnyDatabase>.Difference,
        forKey _: AnyCodingKey
    ) throws
}

/// A proxy to a record container OR snapshot.
final class _DatabaseRecordProxy: CancellablesHolder {
    private enum OperationType {
        case read
        case write
    }
    
    private(set) var base: _DatabaseRecordProxyBase
    
    let recordID: AnyDatabaseRecord.ID
    
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
    
    func decodeValue<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value {
        try base.decodeValue(type, forKey: key)
    }
    
    func encodeValue<Value>(_ value: Value, forKey key: AnyCodingKey) throws {
        try base.encodeValue(value, forKey: key)
    }
    
    func decodeValue(forKey key: AnyCodingKey) throws -> Any? {
        try base.decodeValue(forKey: key)
    }
    
    func encodeValue(_ payload: Any?, forKey key: AnyCodingKey) throws {
        try base.encodeValue(payload, forKey: key)
    }
    
    func decodeRelationship(
        forKey key: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        try base.decodeRelationship(forKey: key)
    }
    
    func encodeRelationship(
        relationship: RelatedDatabaseRecordIdentifiers<AnyDatabase>,
        forKey key: AnyCodingKey
    ) throws {
        try base.encodeRelationship(relationship, forKey: key)
    }
    
    func encodeRelationshipDiff(
        diff: RelatedDatabaseRecordIdentifiers<AnyDatabase>.Difference,
        forKey key: AnyCodingKey
    ) throws {
        try base.encodeRelationshipDiff(diff, forKey: key)
    }
    
    func decodeAndReencodeRelationship(
        forKey key: AnyCodingKey,
        operation: (inout RelatedDatabaseRecordIdentifiers<AnyDatabase>) throws -> Void
    ) throws {
        let currentRelationship = try decodeRelationship(forKey: key)
        var newRelationship = currentRelationship
        
        try operation(&newRelationship)
        
        try encodeRelationshipDiff(diff: newRelationship.difference(from: currentRelationship), forKey: key)
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
