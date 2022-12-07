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

    public func decode<Value>(
        _ type: Value.Type, forKey key: AnyCodingKey
    ) throws -> Value {
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

    public func decodeRelationship(
        ofType type: DatabaseRecordRelationshipType,
        forKey key: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        try record.decodeRelationship(ofType: type, forKey: key)
    }
}

extension _DatabaseRecordDataDecoder {
    public func unsafeDecodeValue(forKey key: AnyCodingKey) throws -> Any? {
        guard let entitySchema = recordSchema as? _Schema.Entity else {
            throw _Error.entitySchemaRequired
        }

        let property = try entitySchema.property(named: key.stringValue)

        switch property {
            case let property as _Schema.Entity.Attribute: do {
                if try !containsValue(forKey: key) {
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
}

// MARK: - Auxiliary -

extension _DatabaseRecordDataDecoder {
    public enum _Error: _SwiftDB_Error {
        case relationshipCodingUnsupported
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
