//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

/// A record container.
///
/// Designed to wrap a transaction context and a database record to provide slightly higher-level access to a database record.
public final class _TransactionScopedRecord {
    private enum OperationType {
        case read
        case write
    }
    
    let recordSchema: _Schema.Record?
    let record: AnyDatabaseRecord
    let recordUpdater: _CachingRecordUpdater
    let transaction: AnyDatabaseTransaction
    
    private let _SwiftDB_taskContext: _SwiftDB_TaskContext
    
    public let _taskRuntimeLink: _SwiftDB_TaskRuntimeLink
    
    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord,
        transaction: AnyDatabaseTransaction
    ) throws {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
        self._taskRuntimeLink = .init(from: try _SwiftDB_taskContext._taskRuntime.unwrap())
        self.recordSchema = recordSchema
        self.record = record
        self.recordUpdater = try .init(recordSchema: recordSchema, record: record, onUpdate: { update in
            try! transaction.updateRecord(record.id, with: update)
        })
        self.transaction = transaction
    }
    
    private func scope<T>(
        _ operationType: OperationType,
        perform operation: (_SwiftDB_TaskContext) throws -> T
    ) throws -> T {
        switch operationType {
            case .read:
                return try _withSwiftDBTaskContext(_SwiftDB_taskContext) { context in
                    try operation(context)
                }
            case .write:
                return try _withSwiftDBTaskContext(_SwiftDB_taskContext) { context in
                    try context._taskRuntime.unwrap()._scopeRecordMutation {
                        try operation(context)
                    }
                }
        }
    }
}

extension _TransactionScopedRecord: _DatabaseRecordProxyBase {
    public var allKeys: [AnyCodingKey] {
        record.allKeys
    }
    
    public func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        try scope(.read) { _ in
            try recordUpdater.containsValue(forKey: key)
        }
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value {
        try scope(.read) { _ in
            try recordUpdater.decodeValue(type, forKey: key)
        }
    }
    
    public func encode<Value>(_ value: Value, forKey key: AnyCodingKey) throws {
        try scope(.write) { _ in
            recordUpdater.unsafeEncodeValue(value, forKey: key)
        }
    }
    
    public func unsafeDecodeValue(forKey key: AnyCodingKey) throws -> Any? {
        try recordUpdater.unsafeDecodeValue(forKey: AnyCodingKey(key))
    }
    
    public func unsafeEncodeValue(_ value: Any?, forKey key: AnyCodingKey) throws {
        recordUpdater.unsafeEncodeValue(value, forKey: AnyCodingKey(key))
    }
}

extension _TransactionScopedRecord {
    public func primaryKeyOrRecordID() throws -> _RecordFieldPayload.PrimaryKeyOrRecordID {
        do {
            return .primaryKey(value: try decodePrimaryKeyValue().unwrap())
        } catch {
            return try .init(from: record.id)
        }
    }
    
    public func decodeFieldPayload(forKey key: AnyCodingKey) throws -> _RecordFieldPayload? {
        guard let entitySchema = recordSchema as? _Schema.Entity else {
            throw _Error.recordSchemaRequired
        }
        
        let property = try entitySchema.property(named: key.stringValue)
        
        switch property {
            case is _Schema.Entity.Attribute:
                return try unsafeDecodeValue(forKey: key).map(_RecordFieldPayload.init(from:))
            case is _Schema.Entity.Relationship:
                return try .relationship(
                    primaryKeysOrRecordIdentifiers: decodeRelatedRecordIDs(forKey: key)
                )
            default:
                throw _Error.unknownPropertyType(property.type, forKey: key)
        }
    }
    
    private func decodeRelatedRecordIDs(
        forKey key: AnyCodingKey
    ) throws -> _RecordFieldPayload.RelatedPrimaryKeysOrRecordIDs {
        let relationshipType = try relationshipType(forKey: key)
        let relationship = try record.decodeRelationship(ofType: relationshipType, forKey: key)
        
        switch relationship {
            case .toOne(let recordID):
                return .toOne(keyOrIdentifier: try recordID.map({ try .init(from: $0) }))
            case .toUnorderedMany(let recordIDs):
                return try .toUnorderedMany(keysOrIdentifiers: Set(recordIDs.map({ try .init(from: $0) })))
            case .toOrderedMany(let recordIDs):
                return try .toOrderedMany(keysOrIdentifiers: recordIDs.map({ try .init(from: $0) }))
        }
    }
    
    private func decodePrimaryKeyValue() throws -> _RecordFieldPayload? {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw _Error.recordSchemaRequired
        }
        
        let uniqueAttributes = schema.attributes.filter({ $0.attributeConfiguration.traits.contains(.guaranteedUnique) })
        
        guard uniqueAttributes.count == 1, let attribute = uniqueAttributes.first else {
            throw _Error.failedToResolvePrimaryKey
        }
        
        return try decodeFieldPayload(forKey: AnyCodingKey(stringValue: attribute.name))
    }
    
    private func relationshipType(forKey key: AnyCodingKey) throws -> DatabaseRecordRelationshipType {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw _Error.recordSchemaRequired
        }
        
        return .destinationType(from: try schema.relationship(named: key.stringValue))
    }
}

// MARK: - Auxiliary -

extension _TransactionScopedRecord {
    enum _Error: _SwiftDB_Error {
        case recordSchemaRequired
        case failedToResolvePrimaryKey
        case unknownPropertyType(Any, forKey: CodingKey)
        case attemptedToDecodeRelationship(forKey: CodingKey)
        case attemptedToEncodeRelationship(forKey: CodingKey)
    }
}

extension _SwiftDB_TaskContext {
    func _transactionScopedContainer(
        for record: AnyDatabaseRecord,
        transaction: AnyDatabaseTransaction
    ) throws -> _TransactionScopedRecord {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)
        
        return try .init(
            _SwiftDB_taskContext: self,
            recordSchema: recordSchema,
            record: record,
            transaction: transaction
        )
    }
}
