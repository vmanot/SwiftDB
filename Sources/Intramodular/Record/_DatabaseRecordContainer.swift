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
    
    private let transactionContext: DatabaseTransactionContext
    
    public let transactionLink: _DatabaseTransactionLink
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        record.objectWillChange
    }
    
    init(
        transactionContext: DatabaseTransactionContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) {
        self.transactionContext = transactionContext
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
                return try withDatabaseTransactionContext(transactionContext) { context in
                    try operation(context)
                }
            case .write:
                return try withDatabaseTransactionContext(transactionContext) { context in
                    try context.transaction._scopeRecordMutation {
                        try operation(context)
                    }
                }
        }
    }
}

extension _DatabaseRecordContainer {
    private enum DecodingError: Error {
        case entitySchemaRequired
        case failedToResolvePrimaryKey
        case unknownPropertyType(Any, forKey: CodingKey)
    }
    
    public func containsValue(forKey key: CodingKey) throws -> Bool {
        try scope(.read) { _ in
            record.containsValue(forKey: key)
        }
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
            if let value = value as? any EntityRelatable {
                try value.encode(to: self, forKey: key)
            } else {
                try record.encode(value, forKey: key)
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
    
    public func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws {
        try scope(.write) { _ in
            try record.setInitialValue(value(), forKey: key)
        }
    }
    
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try scope(.read) { _ in
            try record.relationship(for: key)
        }
    }
}

extension _DatabaseRecordContainer {
    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload? {
        guard let entitySchema = recordSchema as? _Schema.Entity else {
            throw DecodingError.entitySchemaRequired
        }
        
        let property = try entitySchema.property(named: key.stringValue)
        
        return try scope(.read) { _ in
            switch property {
                case let property as _Schema.Entity.Attribute: do {
                    if property.propertyConfiguration.isOptional, try !containsValue(forKey: key) {
                        return nil
                    }
                    
                    let attributeType = property.attributeConfiguration.type
                    
                    func _decodeValueForType<T>(_ type: T.Type) throws -> Any {
                        try self.decode(type, forKey: key)
                    }
                    
                    let value = try _openExistential(attributeType._swiftType, do: _decodeValueForType)
                    
                    return try _RecordFieldPayload(from: value)
                }
                case is _Schema.Entity.Relationship: do {
                    return try .relationship(primaryKeysOrRecordIdentifiers: decodeRelatedPrimaryKeysOrRecordIDs(forKey: key))
                }
                default:
                    throw DecodingError.unknownPropertyType(property.type, forKey: key)
            }
        }
    }
    
    func encodeFieldPayload(_ payload: Any?, forKey key: CodingKey) throws {
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
}

extension _DatabaseRecordContainer {
    private func decodePrimaryKeyValue() throws -> _RecordFieldPayload? {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw DecodingError.entitySchemaRequired
        }
        
        let uniqueAttributes = schema.attributes.filter({ $0.attributeConfiguration.traits.contains(.guaranteedUnique) })
        
        guard uniqueAttributes.count == 1, let attribute = uniqueAttributes.first else {
            throw DecodingError.failedToResolvePrimaryKey
        }
        
        return try decodeFieldPayload(forKey: AnyStringKey(stringValue: attribute.name))
    }
    
    private func relationshipType(forKey key: CodingKey) throws -> DatabaseRecordRelationshipType {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw DecodingError.entitySchemaRequired
        }
        
        return .destinationType(from: try schema.relationship(named: key.stringValue))
    }
    
    private func decodeRelatedPrimaryKeysOrRecordIDs(forKey key: CodingKey) throws -> _RelatedPrimaryKeysOrRecordIDs {
        try scope(.read) { context in
            let containedRelatedRecords = try _relatedRecords(forKey: key)
            
            let result: _RelatedPrimaryKeysOrRecordIDs
            
            switch containedRelatedRecords {
                case .toOne(let record):
                    let recordContainer = try record.map(context._recordContainer(for:))
                    
                    result = try .toOne(keyOrIdentifier: recordContainer?.primaryKeyOrRecordID())
                case .toMany(let records):
                    let recordContainers = try records.map(context._recordContainer(for:))
                    
                    result = try .toMany(keysOrIdentifiers: Set(recordContainers.map({ try $0.primaryKeyOrRecordID() })))
                case .orderedToMany(let records):
                    let recordContainers = try records.map(context._recordContainer(for:))
                    
                    result = try .orderedToMany(keysOrIdentifiers: recordContainers.map({ try $0.primaryKeyOrRecordID() }))
            }
            
            return result
        }
    }
    
    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID {
        do {
            return .primaryKey(value: try decodePrimaryKeyValue().unwrap())
        } catch {
            return try .recordID(value: _PersistentTypeRepresentedCodable(cast(record.id, to: Codable.self)))
        }
    }
    
    func _relatedRecords(forKey key: CodingKey) throws -> _RelatedDatabaseRecords {
        let relationshipType = try relationshipType(forKey: key)
        
        switch relationshipType {
            case .toOne:
                let toOneRelationship = try relationship(for: key).toOneRelationship()
                let record = try toOneRelationship.getRecord()
                
                return _RelatedDatabaseRecords.toOne(record)
            case .toMany:
                let toManyRelationship = try relationship(for: key).toManyRelationship()
                
                return try _RelatedDatabaseRecords.toMany(toManyRelationship.all())
            case .orderedToMany:
                let toManyRelationship = try relationship(for: key).toManyRelationship()
                
                return try _RelatedDatabaseRecords.toMany(toManyRelationship.all())
        }
    }
}

public enum _RelatedDatabaseRecords: Sequence {
    case toOne(AnyDatabaseRecord?)
    case toMany(Array<AnyDatabaseRecord>)
    case orderedToMany(Array<AnyDatabaseRecord>)
    
    public func makeIterator() -> Array<AnyDatabaseRecord>.Iterator {
        switch self {
            case .toOne(let record):
                return (record.map({ [$0] }) ?? []).makeIterator()
            case .toMany(let records):
                return records.makeIterator()
            case .orderedToMany(let records):
                return records.makeIterator()
        }
    }
}

public indirect enum _RecordFieldPayload: Codable, Hashable {
    public indirect enum _EntityAttributeValue: Codable, Hashable {
        case primitive(value: _PersistentTypeRepresentedCodable)
        case array(value: [_PersistentTypeRepresentedCodable])
        case dictionary(value: [_PersistentTypeRepresentedCodable: _PersistentTypeRepresentedCodable])
        case object(value: _PersistentTypeRepresentedCodable)
    }
    
    case attribute(value: _EntityAttributeValue)
    case relationship(primaryKeysOrRecordIdentifiers: _RelatedPrimaryKeysOrRecordIDs)
    
    public init(from value: Any) throws {
        if let value = value as? _RecordFieldPayloadConvertible {
            self = try value._toRecordFieldPayload()
        } else {
            self = .attribute(value: .object(value: _PersistentTypeRepresentedCodable(try cast(value, to: Codable.self))))
        }
    }
}

public indirect enum _RelatedPrimaryKeysOrRecordIDs: Codable, Hashable {
    case toOne(keyOrIdentifier: _PrimaryKeyOrRecordID?)
    case toMany(keysOrIdentifiers: Set<_PrimaryKeyOrRecordID>)
    case orderedToMany(keysOrIdentifiers: [_PrimaryKeyOrRecordID])
}

public indirect enum _PrimaryKeyOrRecordID: Codable, Hashable {
    case primaryKey(value: _RecordFieldPayload)
    case recordID(value: _PersistentTypeRepresentedCodable)
}
