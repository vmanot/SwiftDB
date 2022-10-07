//
// Copyright (c) Vatsal Manot
//

import Swallow

public final class _DatabaseRecordContainer: ObservableObject {
    private enum OperationType {
        case read
        case write
    }
    
    let recordSchema: _Schema.Record?
    let record: AnyDatabaseRecord
    
    private let transaction: any DatabaseTransaction
    
    public let transactionLink: _DatabaseTransactionLink
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        record.objectWillChange
    }
    
    init(
        transactionContext: DatabaseTransactionContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) {
        self.transaction = transactionContext.transaction
        self.transactionLink = .init(from: transactionContext.transaction)
        self.recordSchema = recordSchema
        self.record = record
    }
    
    private func scope<T>(
        _ operationType: OperationType,
        perform operation: (DatabaseTransactionContext) throws -> T
    ) throws -> T {
        switch operationType {
            case .read:
                return try transaction.scope { context in
                    try operation(context)
                }
            case .write:
                return try transaction.scope { context in
                    try transaction._scopeRecordMutation {
                        try operation(context)
                    }
                }
        }
    }
}

extension _DatabaseRecordContainer {
    public func containsValue(forKey key: CodingKey) -> Bool {
        record.containsValue(forKey: key)
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try scope(.read) { _ in
            if let type = type as? any EntityRelatable.Type {
                return try cast(try type.decode(from: self, forKey: key), to: Value.self)
            } else {
                return try record.decode(type, forKey: key)
            }
        }
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try scope(.write) { _ in
            try record.encode(value, forKey: key)
        }
    }
    
    public func decodeFieldPayload(forKey key: CodingKey) throws -> Any {
        enum DecodingError: Error {
            case entitySchemaRequired
            case unknownPropertyType(Any, forKey: CodingKey)
        }
        
        guard let entitySchema = recordSchema as? _Schema.Entity else {
            throw DecodingError.entitySchemaRequired
        }
        
        let property = try entitySchema.property(named: key.stringValue)
        
        return try scope(.read) { _ in
            switch property {
                case let property as _Schema.Entity.Attribute: do {
                    let attributeType = property.attributeConfiguration.type
                    
                    func _decodeValueForType<T>(_ type: T.Type) throws -> Any {
                        try self.decode(type, forKey: key)
                    }
                    
                    return try _openExistential(attributeType._swiftType, do: _decodeValueForType)
                }
                case let property as _Schema.Entity.Relationship: do {
                    print(property)
                    TODO.unimplemented
                }
                default:
                    throw DecodingError.unknownPropertyType(property.type, forKey: key)
            }
        }
    }
    
    public func encodeFieldPayload(_ payload: Any?, forKey key: CodingKey) throws {
        try scope(.write) { _ in
            if let payload = payload {
                func _encodeValue<T>(_ value: T) throws {
                    try self.encode(value, forKey: key)
                }
                
                try _openExistential(payload, do: _encodeValue)
            } else {
                try self.encode(Optional<Any>.none, forKey: key)
            }
        }
    }
    
    public func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws {
        try scope(.write) { _ in
            try record.setInitialValue(value(), forKey: key)
        }
    }
    
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try scope(.read) { _ in
            AnyDatabaseRecordRelationship(erasing: try record.relationship(for: key))
        }
    }
}

public enum _RecordFieldPayload: Codable, Hashable {
    public enum _EntityAttributeValue: Codable, Hashable {
        case primitive(value: _TypePersistingAnyCodable)
        case array(value: [_TypePersistingAnyCodable])
        case dictionary(value: [_TypePersistingAnyCodable: _TypePersistingAnyCodable])
        case object(value: _TypePersistingAnyCodable)
    }
    
    public enum RelatedIdentifiers: Codable, Hashable {
        case toOne(id: _TypePersistingAnyCodable)
        case toMany(ids: Set<_TypePersistingAnyCodable>)
        case orderedToMany(ids: [_TypePersistingAnyCodable])
    }
    
    case attribute(value: _EntityAttributeValue)
    case relationship(identifiers: RelatedIdentifiers)
}
