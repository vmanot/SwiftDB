//
// Copyright (c) Vatsal Manot
//

import Swallow

public final class _AnyDatabaseRecordContainer: ObservableObject {
    private enum OperationType {
        case read
        case write
    }

    let recordSchema: _Schema.Record?
    let record: AnyDatabaseRecord
    
    private let transaction: any DatabaseTransaction
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        record.objectWillChange
    }
    
    init(
        transactionContext: DatabaseTransactionContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) {
        self.transaction = transactionContext.transaction
        self.recordSchema = recordSchema
        self.record = record
    }
    
    private func _withContext<T>(
        _ operationType: OperationType,
        context: (DatabaseTransactionContext) throws -> T
    ) rethrows -> T {
        switch operationType {
            case .read:
                return try transaction._withTransactionContext {
                    try context($0)
                }
            case .write:
                return try transaction._scopeRecordMutation {
                    try transaction._withTransactionContext {
                        try context($0)
                    }
                }
        }
    }
}

extension _AnyDatabaseRecordContainer {
    public func containsValue(forKey key: CodingKey) -> Bool {
        record.containsValue(forKey: key)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try _withContext(.write) { _ in
            try record.encode(value, forKey: key)
        }
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try _withContext(.read) { _ in
            if let type = type as? any EntityRelatable.Type {
                return try cast(try type.decode(from: record, forKey: key), to: Value.self)
            } else {
                return try record.decode(type, forKey: key)
            }
        }
    }
    
    public func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws {
        try _withContext(.write) { _ in
            try record.setInitialValue(value(), forKey: key)
        }
    }
    
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try _withContext(.read) { _ in
            try record.relationship(for: key).eraseToAnyDatabaseRelationship()
        }
    }
}
