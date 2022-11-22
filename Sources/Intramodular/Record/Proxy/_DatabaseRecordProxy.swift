//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public protocol _DatabaseRecordProxyBase {
    
}

/// A proxy to a record container OR snapshot.
public final class _DatabaseRecordProxy: ObservableObject {
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
    private enum DecodingError: Error {
        case entitySchemaRequired
        case failedToResolvePrimaryKey
        case unknownPropertyType(Any, forKey: CodingKey)
    }
    
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
    
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try base.relationship(for: key)
    }
}

extension _DatabaseRecordProxy {
    private func recordCoder() throws -> _DatabaseRecordCoder {
        try base.recordCoder()
    }
    
    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID {
        try recordCoder().primaryKeyOrRecordID()
    }
    
    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload? {
        try recordCoder().decodeFieldPayload(forKey: key)
    }
    
    func encodeFieldPayload(_ payload: Any?, forKey key: CodingKey) throws {
        try recordCoder().encodeFieldPayload(payload, forKey: key)
    }
}

// MARK: - Auxiliary -

extension _DatabaseRecordProxy {
    enum _Error: Swift.Error {
        
    }
}
