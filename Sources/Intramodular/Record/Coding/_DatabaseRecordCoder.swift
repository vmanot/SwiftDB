//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public struct _DatabaseRecordCoder {
    let recordSchema: _Schema.Record?
    let record: AnyDatabaseRecord

    private let _SwiftDB_taskContext: _SwiftDB_TaskContext

    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) throws {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
        self.recordSchema = recordSchema
        self.record = record
    }
}

extension _DatabaseRecordCoder {
    public func containsValue(forKey key: CodingKey) throws -> Bool {
        record.containsValue(forKey: key)
    }

    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        if type is any EntityRelatable.Type {
            throw _Error.relationshipCodingUnsupported
        } else {
            // Special handling for RawRepresentable types.
            if let rawRepresentableType = type as? any RawRepresentable.Type,
               case .primitive = _Schema.Entity.AttributeType(from: rawRepresentableType)
            {
                let rawValue = try record._opaque_decode(rawRepresentableType._opaque_RawValue, forKey: key)

                return try cast(
                    try rawRepresentableType.init(_opaque_rawValue: rawValue),
                    to: Value.self
                )
            }

            return try record.decode(type, forKey: key)
        }
    }

    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        if value is any EntityRelatable {
            throw _Error.relationshipCodingUnsupported
        } else {
            try record.encode(value, forKey: key)
        }
    }
}

extension _DatabaseRecordCoder {
    public func decodeFieldValue(forKey key: CodingKey) throws -> Any? {
        guard let entitySchema = recordSchema as? _Schema.Entity else {
            throw _Error.entitySchemaRequired
        }
        
        let property = try entitySchema.property(named: key.stringValue)
        
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
                
                return value
            }
            case is _Schema.Entity.Relationship: do {
                throw _Error.relationshipCodingUnsupported
            }
            default:
                throw _Error.unknownPropertyType(property.type, forKey: key)
        }
    }

    func encodeFieldValue(_ payload: Any?, forKey key: CodingKey) throws {
        if let payload = payload {
            func _encodeValue<T>(_ value: T) throws {
                try self.encode(value, forKey: key)
            }
            
            try _openExistential(payload, do: _encodeValue)
        } else {
            try self.encode(Optional<Any>.none, forKey: key)
        }
    }
    
    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload? {
        guard let entitySchema = recordSchema as? _Schema.Entity else {
            throw _Error.entitySchemaRequired
        }
        
        let property = try entitySchema.property(named: key.stringValue)
        
        switch property {
            case is _Schema.Entity.Attribute:
                return try decodeFieldValue(forKey: key).map(_RecordFieldPayload.init(from:))
            case is _Schema.Entity.Relationship: do {
                return try .relationship(primaryKeysOrRecordIdentifiers: decodeRelatedPrimaryKeysOrRecordIDs(forKey: key))
            }
            default:
                throw _Error.unknownPropertyType(property.type, forKey: key)
        }
    }
}

extension _DatabaseRecordCoder {
    private func decodePrimaryKeyValue() throws -> _RecordFieldPayload? {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw _Error.entitySchemaRequired
        }

        let uniqueAttributes = schema.attributes.filter({ $0.attributeConfiguration.traits.contains(.guaranteedUnique) })

        guard uniqueAttributes.count == 1, let attribute = uniqueAttributes.first else {
            throw _Error.failedToResolvePrimaryKey
        }

        return try decodeFieldPayload(forKey: AnyStringKey(stringValue: attribute.name))
    }

    private func relationshipType(forKey key: CodingKey) throws -> DatabaseRecordRelationshipType {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw _Error.entitySchemaRequired
        }

        return .destinationType(from: try schema.relationship(named: key.stringValue))
    }

    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID {
        do {
            return .primaryKey(value: try decodePrimaryKeyValue().unwrap())
        } catch {
            return try .init(from: record.id)
        }
    }

    func decodeRelatedPrimaryKeysOrRecordIDs(forKey key: CodingKey) throws -> _RelatedPrimaryKeysOrRecordIDs {
        let relationshipType = try relationshipType(forKey: key)

        switch relationshipType {
            case .toOne:
                let relationship = try record.relationship(for: key).toOneRelationship()
                let recordID = try relationship.getRecord()

                return .toOne(keyOrIdentifier: try recordID.map({ try .init(from: $0) })) // FIXME:!!! Figure out a way to get the primary key.
            case .toMany:
                let relationship = try record.relationship(for: key).toManyRelationship()
                let recordCoders = try relationship.all().map({ try _SwiftDB_taskContext._recordCoder(for: $0) })

                return try .toMany(keysOrIdentifiers: Set(recordCoders.map({ try $0.primaryKeyOrRecordID() })))
            case .orderedToMany:
                let relationship = try record.relationship(for: key).toManyRelationship()
                let recordCoders = try relationship.all().map({ try _SwiftDB_taskContext._recordCoder(for: $0) })

                return try .orderedToMany(keysOrIdentifiers: recordCoders.map({ try $0.primaryKeyOrRecordID() }))
        }
    }
}

// MARK: - Auxiliary -

extension _DatabaseRecordCoder {
    public enum _Error: _SwiftDB_Error {
        case relationshipCodingUnsupported
        case entitySchemaRequired
        case failedToResolvePrimaryKey
        case unknownPropertyType(Any, forKey: CodingKey)
    }
}

extension AnyDatabaseRecord {
    fileprivate func _opaque_decode(_ type: Any.Type, forKey key: CodingKey) throws -> Any {
        func _decodeValueForType<T>(_ type: T.Type) throws -> Any {
            try self.decode(type, forKey: key)
        }

        return try _openExistential(type, do: _decodeValueForType)
    }
}

extension _SwiftDB_TaskContext {
    fileprivate func _recordCoder(
        for record: AnyDatabaseRecord
    ) throws -> _DatabaseRecordCoder {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)

        return try .init(_SwiftDB_taskContext: self, recordSchema: recordSchema, record: record)
    }
}
