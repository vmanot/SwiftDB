//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swift

extension DatabaseSchema.Entity {
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
    
    public indirect enum AttributeType: Codable, Hashable {
        public struct ObjectType: Codable, Hashable {
            public let identity: PersistableTypeIdentity
        }
        
        case primitive(type: PrimitiveAttributeType)
        case array(elementType: AttributeType)
        case dictionary(keyType: AttributeType, valueType: AttributeType)
        case object(type: ObjectType)
    }

    public enum OldAttributeType: Codable, Hashable {
        case undefined
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
        case transformable(className: String, transformerName: String? = nil)
        case objectID
        
        public var className: String? {
            if case let .transformable(className, _) = self {
                return className
            } else {
                return nil
            }
        }
        
        public var transformerName: String? {
            if case let .transformable(_, transformerName) = self {
                return transformerName
            } else {
                return nil
            }
        }
        
        public static func transformable(class: AnyClass, transformerName: String? = nil) -> Self {
            .transformable(className: NSStringFromClass(`class`), transformerName: transformerName)
        }
    }
}
