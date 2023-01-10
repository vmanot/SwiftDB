//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _Schema.Entity {
    /// The types of primitive attributes supported by SwiftDB's canonical schema representation.
    public enum PrimitiveAttributeType: String, Codable, Hashable {
        case integer16
        case integer32
        case integer64
        case decimal
        case double
        case float
        case string
        case boolean
        case date
        case binaryData
        case UUID
        case URI
        
        public var _swiftType: any Hashable.Type {
            switch self {
                case .integer16:
                    return Int16.self
                case .integer32:
                    return Int32.self
                case .integer64:
                    return Int.self
                case .decimal:
                    return Decimal.self
                case .double:
                    return Double.self
                case .float:
                    return Float.self
                case .string:
                    return String.self
                case .boolean:
                    return Bool.self
                case .date:
                    return Date.self
                case .binaryData:
                    return Data.self
                case .UUID:
                    return Foundation.UUID.self
                case .URI:
                    return URL.self
            }
        }
    }
    
    /// The types of attributes supported by SwiftDB's canonical schema representation.
    public indirect enum AttributeType: Codable, Hashable {
        public struct ObjectType: Codable, Hashable {
            public let identity: _PersistentTypeRepresentation
        }
        
        case primitive(type: PrimitiveAttributeType)
        case array(elementType: AttributeType)
        case dictionary(keyType: AttributeType, valueType: AttributeType)
        case object(type: ObjectType)
        
        public init(from type: Any.Type) {
            let type = (type as? _opaque_Optional.Type)?._opaque_Optional_Wrapped ?? type
            
            if let type = type as? any _EntityAttributeSchemaRepresentable.Type {
                self = type.toSchemaEntityAttributeType()
            } else {
                self = .object(type: .init(identity: .init(from: type)))
                
                if let type = type as? any RawRepresentable.Type,
                   let rawValueType = type._opaque_RawValue as? _EntityAttributeSchemaRepresentable.Type,
                   case .primitive(let primitiveType) = rawValueType.toSchemaEntityAttributeType()
                {
                    self = .primitive(type: primitiveType)
                } else {
                    self = .object(type: .init(identity: .init(from: type)))
                }
            }
        }
        
        public var _swiftType: Any.Type {
            get throws {
                switch self {
                    case .primitive(let type):
                        return type._swiftType
                    case .array(let elementType):
                        return try elementType._swiftType
                    case .dictionary(let keyType, let valueType):
                        return try makeDictionaryType(keyType: keyType._swiftType, valueType: valueType._swiftType)
                    case .object(let type):
                        return try type.identity.resolveType()
                }
            }
        }
    }
}

// MARK: - Auxiliary -

fileprivate extension Hashable {
    static func dictionaryType(valueType: Any.Type) -> Any.Type {
        func _dictionaryType<T>(_ instance: T.Type) -> Any.Type  {
            return Dictionary<Self, T>.self
        }
        
        return _openExistential(valueType, do: _dictionaryType)
    }
}

func makeDictionaryType(keyType: Any.Type, valueType: Any.Type) throws -> Any.Type {
    try cast(keyType, to: any Hashable.Type.self).dictionaryType(valueType: valueType)
}
