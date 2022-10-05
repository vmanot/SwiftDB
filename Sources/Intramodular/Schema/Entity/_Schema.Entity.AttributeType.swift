//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

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
    }
    
    /// The types of attributes supported by SwiftDB's canonical schema representation.
    public indirect enum AttributeType: Codable, Hashable {
        public struct ObjectType: Codable, Hashable {
            public let identity: PersistableTypeIdentity
        }
        
        case primitive(type: PrimitiveAttributeType)
        case array(elementType: AttributeType)
        case dictionary(keyType: AttributeType, valueType: AttributeType)
        case object(type: ObjectType)
        
        public init(from type: Any.Type) {
            if let type = type as? any _EntityAttributeSchemaRepresentable.Type {
                self = type.to_SchemaEntityAttributeType()
            } else {
                self = .object(type: .init(identity: .init(from: type)))
            }
        }
    }
}
