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
    
    mutating func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    mutating func removeValueOrRelationship(forKey key: CodingKey) throws
    
    func decodeUnsafeFieldValue(forKey key: CodingKey) throws -> Any?
    
    mutating func encodeUnsafeFieldValue(_ payload: Any?, forKey key: CodingKey) throws
    
    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload?
    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID
}

/// A proxy to a record container OR snapshot.
public final class _DatabaseRecordProxy: CancellablesHolder, ObservableObject {
    private enum OperationType {
        case read
        case write
    }
    
    public private(set) var base: _DatabaseRecordProxyBase
    
    public let recordID: AnyDatabaseRecord.ID
    
    public lazy var objectWillChange: AnyObjectWillChangePublisher = {
        (base as? _DatabaseRecordContainer)?.objectWillChange ?? .init(erasing: ObservableObjectPublisher())
    }()
    
    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) throws {
        self.base = try _DatabaseRecordContainer(
            _SwiftDB_taskContext: _SwiftDB_taskContext,
            recordSchema: recordSchema,
            record: record
        )
        self.recordID = record.id
    }
}

extension _DatabaseRecordProxy {
    var allKeys: [CodingKey] {
        base.allKeys
    }
    
    func containsValue(forKey key: CodingKey) throws -> Bool {
        try base.containsValue(forKey: key)
    }
    
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }
    
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try base.encode(value, forKey: key)
    }
    
    func removeValueOrRelationship(forKey key: CodingKey) throws {
        try base.removeValueOrRelationship(forKey: key)
    }
    
    func decodeUnsafeFieldValue(forKey key: CodingKey) throws -> Any? {
        try base.decodeUnsafeFieldValue(forKey: key)
    }
    
    func encodeUnsafeFieldValue(_ payload: Any?, forKey key: CodingKey) throws {
        try base.encodeUnsafeFieldValue(payload, forKey: key)
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
