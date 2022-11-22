//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Merge
import Swallow

public protocol _DatabaseRecordProxyBase {
    var allKeys: [CodingKey] { get }
    
    func containsValue(forKey key: CodingKey) throws -> Bool
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    func removeValueOrRelationship(forKey key: CodingKey) throws
    func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws
    
    func decodeFieldValue(forKey key: CodingKey) throws -> Any?
    func encodeFieldValue(_ payload: Any?, forKey key: CodingKey) throws
    
    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload?
    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID
}

/// A proxy to a record container OR snapshot.
public final class _DatabaseRecordProxy: CancellablesHolder, ObservableObject {
    private enum OperationType {
        case read
        case write
    }
    
    public let recordID: AnyDatabaseRecord.ID
    
    private let base: _DatabaseRecordContainer
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.objectWillChange
    }
    
    init(base: _DatabaseRecordContainer) {
        self.recordID = base.record.id
        self.base = base
    }
    
    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) throws {
        self.recordID = record.id
        self.base = try .init(
            _SwiftDB_taskContext: _SwiftDB_taskContext,
            recordSchema: recordSchema,
            record: record
        )
    }
}

extension _DatabaseRecordProxy {
    public var record: AnyDatabaseRecord {
        base.record
    }
}

extension _DatabaseRecordProxy {
    public var allKeys: [CodingKey] {
        base.allKeys
    }
    
    public func containsValue(forKey key: CodingKey) throws -> Bool {
        try base.containsValue(forKey: key)
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try base.encode(value, forKey: key)
    }
    
    public func removeValueOrRelationship(forKey key: CodingKey) throws {
        try base.removeValueOrRelationship(forKey: key)
    }
    
    public func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws {
        try base.setInitialValue(value(), forKey: key)
    }
    
    func decodeFieldValue(forKey key: CodingKey) throws -> Any? {
        try base.decodeFieldValue(forKey: key)
    }
    
    func encodeFieldValue(_ payload: Any?, forKey key: CodingKey) throws {
        try base.encodeFieldValue(payload, forKey: key)
    }
    
    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload? {
        try base.decodeFieldPayload(forKey: key)
    }
    
    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID {
        try base.primaryKeyOrRecordID()
    }
}

// MARK: - Auxiliary -

extension _DatabaseRecordProxy {
    enum _Error: Swift.Error {
        
    }
}
