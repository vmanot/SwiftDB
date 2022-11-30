//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

/// A record container.
///
/// Designed to wrap a transaction context and a database record to provide slightly higher-level access to a database record.
public final class _DatabaseRecordContainer: ObservableObject {
    private enum OperationType {
        case read
        case write
    }
    
    let recordSchema: _Schema.Record?
    let record: AnyDatabaseRecord
    
    private let _SwiftDB_taskContext: _SwiftDB_TaskContext
    
    public let _taskRuntimeLink: _SwiftDB_TaskRuntimeLink
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        record.objectWillChange
    }
    
    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) throws {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
        self._taskRuntimeLink = .init(from: try _SwiftDB_taskContext._taskRuntime.unwrap())
        self.recordSchema = recordSchema
        self.record = record
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

extension _DatabaseRecordContainer: _DatabaseRecordProxyBase {
    public var allKeys: [CodingKey] {
        record.allKeys
    }

    public func recordCoder() throws -> _DatabaseRecordCoder {
        try .init(_SwiftDB_taskContext: _SwiftDB_taskContext, recordSchema: recordSchema, record: record)
    }
    
    public func containsValue(forKey key: CodingKey) throws -> Bool {
        try scope(.read) { _ in
            try recordCoder().containsValue(forKey: key)
        }
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try scope(.read) { _ in
            if let type = type as? any EntityRelatable.Type {
                return try cast(try type.decode(from: self, forKey: key), to: Value.self)
            } else {
                return try recordCoder().decode(type, forKey: key)
            }
        }
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try scope(.write) { _ in
            if let value = value as? any EntityRelatable {
                var _self: _DatabaseRecordProxyBase = self
                try value.encode(to: &_self, forKey: key)
            } else {
                return try recordCoder().encode(value, forKey: key)
            }
        }
    }
    
    public func removeValueOrRelationship(forKey key: CodingKey) throws {
        guard try containsValue(forKey: key) else {
            return
        }
        
        try scope(.write) {_ in
            try record.removeValueOrRelationship(forKey: key)
        }
    }
        
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try scope(.read) { _ in
            try record.relationship(for: key)
        }
    }
}

extension _DatabaseRecordContainer {
    public func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID {
        try recordCoder().primaryKeyOrRecordID()
    }

    public func decodeUnsafeFieldValue(forKey key: CodingKey) throws -> Any? {
        try recordCoder().decodeUnsafeFieldValue(forKey: key)
    }

    public func encodeUnsafeFieldValue(_ payload: Any?, forKey key: CodingKey) throws {
        try recordCoder().encodeUnsafeFieldValue(payload, forKey: key)
    }

    public func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload? {
        try recordCoder().decodeFieldPayload(forKey: key)
    }
}
