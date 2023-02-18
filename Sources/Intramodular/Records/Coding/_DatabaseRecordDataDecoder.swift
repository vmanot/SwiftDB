//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public struct _DatabaseRecordDataDecoder {
    let recordSchema: _Schema.Record?
    let record: AnyDatabaseRecord
    
    init(
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord
    ) throws {
        self.recordSchema = recordSchema
        self.record = record
    }
}

extension _DatabaseRecordDataDecoder {
    public func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        record.containsValue(forKey: key)
    }
    
    public func decodeValue<Value>(
        _ type: Value.Type,
        forKey key: AnyCodingKey
    ) throws -> Value {
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
    
    public func decodeValue(forKey key: AnyCodingKey) throws -> Any? {
        let property = try _entitySchema().property(named: key.stringValue)
        
        switch property {
            case let property as _Schema.Entity.Attribute: do {
                if try !containsValue(forKey: key) {
                    return nil
                }
                
                let attributeConfiguration = property.attributeConfiguration
                
                func _decodeValueForType<T>(_ type: T.Type) throws -> Any {
                    try self.decodeValue(type, forKey: key)
                }
                
                let value = try _openExistential(attributeConfiguration._resolveSwiftType(), do: _decodeValueForType)
                
                return value
            }
            case is _Schema.Entity.Relationship: do {
                throw _Error.attemptedToDecodeValueFromRelationshipKey(key)
            }
            default:
                throw _Error.unknownPropertyType(property.type, forKey: key)
        }
    }
    
    public func decodeRelationship(
        forKey key: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        let relationship = try _entitySchema().relationship(named: key.stringValue)
        let relationshipType = DatabaseRecordRelationshipType.destinationType(from: relationship)
        
        return try record.decodeRelationship(ofType: relationshipType, forKey: key)
    }
    
    private func _entitySchema() throws -> _Schema.Entity {
        guard let schema = recordSchema as? _Schema.Entity else {
            throw _Error.entitySchemaRequired
        }
        
        return schema
    }
}

// MARK: - Auxiliary

extension _DatabaseRecordDataDecoder {
    public enum _Error: _SwiftDB_Error {
        case attemptedToDecodeValueFromRelationshipKey(AnyCodingKey)
        case entitySchemaRequired
        case failedToResolvePrimaryKey
        case unknownPropertyType(Any, forKey: CodingKey)
    }
}

extension AnyDatabaseRecord {
    fileprivate func _opaque_decode(_ type: Any.Type, forKey key: AnyCodingKey) throws -> Any {
        func _decodeForType<T>(_ type: T.Type) throws -> Any {
            try self.decode(type, forKey: key)
        }
        
        return try _openExistential(type, do: _decodeForType)
    }
}
