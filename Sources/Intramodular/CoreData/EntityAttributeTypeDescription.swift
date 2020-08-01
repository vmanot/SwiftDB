//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swift

public enum EntityAttributeTypeDescription {
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
    
    public static func transformable(class: AnyClass, transformerName: String? = nil) -> Self {
        .transformable(className: NSStringFromClass(`class`), transformerName: transformerName)
    }
}

extension EntityAttributeTypeDescription {
    public init?(_ type: NSAttributeType) {
        switch type {
            case .undefinedAttributeType:
                self = .undefined
            case .integer16AttributeType:
                self = .integer16
            case .integer32AttributeType:
                self = .integer32
            case .integer64AttributeType:
                self = .integer64
            case .decimalAttributeType:
                self = .decimal
            case .doubleAttributeType:
                self = .double
            case .floatAttributeType:
                self = .float
            case .stringAttributeType:
                self = .string
            case .booleanAttributeType:
                self = .boolean
            case .dateAttributeType:
                self = .date
            case .binaryDataAttributeType:
                self = .binaryData
            case .UUIDAttributeType:
                self = .UUID
            case .URIAttributeType:
                self = .URI
            case .transformableAttributeType:
                return nil
            case .objectIDAttributeType:
                self = .objectID
            @unknown default:
                self = .undefined // FIXME?
        }
    }
}

extension NSAttributeType {
    public init(_ description: EntityAttributeTypeDescription) {
        switch description {
            case .undefined:
                self = .undefinedAttributeType
            case .integer16:
                self = .integer16AttributeType
            case .integer32:
                self = .integer32AttributeType
            case .integer64:
                self = .integer64AttributeType
            case .decimal:
                self = .decimalAttributeType
            case .double:
                self = .doubleAttributeType
            case .float:
                self = .floatAttributeType
            case .string:
                self = .stringAttributeType
            case .boolean:
                self = .booleanAttributeType
            case .date:
                self = .dateAttributeType
            case .binaryData:
                self = .binaryDataAttributeType
            case .UUID:
                self = .UUIDAttributeType
            case .URI:
                self = .URIAttributeType
            case .transformable:
                self = .transformableAttributeType
            case .objectID:
                self = .objectIDAttributeType
        }
    }
}
