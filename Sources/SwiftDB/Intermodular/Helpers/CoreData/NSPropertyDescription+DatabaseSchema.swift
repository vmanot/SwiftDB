//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Runtime
import Swallow

extension NSAttributeDescription {
    public convenience init(_ attribute: _Schema.Entity.Attribute) throws {
        self.init()
        
        let nsAttributeType = _SwiftDB_NSAttributeType(from: attribute.attributeConfiguration.attributeType)
        
        renamingIdentifier = attribute.propertyConfiguration.renamingIdentifier
        name = attribute.name
        isOptional = attribute.propertyConfiguration.isOptional
        isTransient = attribute.propertyConfiguration.isTransient
        attributeType = nsAttributeType.attributeType
        
        if let attributeValueClassName = nsAttributeType.className {
            self.attributeValueClassName = attributeValueClassName
        }
        
        if let valueTransformerName = nsAttributeType.transformerName {
            self.valueTransformerName = valueTransformerName
        }
        
        allowsExternalBinaryDataStorage = attribute.attributeConfiguration.traits.contains(.allowsExternalBinaryDataStorage)
        // preservesValueInHistoryOnDeletion = ...
        
        defaultValue = attribute.attributeConfiguration.defaultValue?.cocoaObjectValue()
    }
}

extension NSRelationshipDescription {
    convenience init(_ description: _Schema.Entity.Relationship) throws {
        self.init()
        
        name = description.name
        isOptional = description.propertyConfiguration.isOptional
        isTransient = description.propertyConfiguration.isTransient
        isOrdered = true
        
        switch description.relationshipConfiguration.cardinality {
            case .oneToOne:
                minCount = isOptional ? 0 : 1
                maxCount = 1
            case .oneToMany:
                minCount = 0
                maxCount = 0
            case .manyToOne:
                minCount = isOptional ? 0 : 1
                maxCount = 1
            case .manyToMany:
                minCount = 0
                maxCount = 0
        }
        
        if let deleteRule = description.relationshipConfiguration.deleteRule {
            self.deleteRule = deleteRule
        }
    }
}

// MARK: - Auxiliary

struct _SwiftDB_NSAttributeType {
    let attributeType: NSAttributeType
    let className: String?
    let transformerName: String?
    
    init(from type: _Schema.Entity.AttributeType) {
        switch type {
            case .primitive(let type):
                self.attributeType = NSAttributeType(type)
                self.className = nil
                self.transformerName = nil
            case .array:
                self.attributeType = .transformableAttributeType
                self.className = NSStringFromClass(NSArray.self)
                self.transformerName = "NSSecureUnarchiveFromData"
            case .dictionary:
                self.attributeType = .transformableAttributeType
                self.className = NSStringFromClass(NSDictionary.self)
                self.transformerName = "NSSecureUnarchiveFromData"
            case .object:
                self.attributeType = .transformableAttributeType
                self.className = NSStringFromClass(NSDictionary.self)
                self.transformerName = "NSSecureUnarchiveFromData"
        }
    }
}

private extension NSAttributeType {
    init(_ description: _Schema.Entity.PrimitiveAttributeType) {
        switch description {
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
        }
    }
}

#if swift(>=5.9)
private extension _Schema.Entity.PrimitiveAttributeType {
    init?(_ type: NSAttributeType) {
        switch type {
            case .undefinedAttributeType:
                return nil
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
                return nil
            case .compositeAttributeType:
                return nil
            @unknown default:
                return nil
        }
    }
}
#else
private extension _Schema.Entity.PrimitiveAttributeType {
    init?(_ type: NSAttributeType) {
        switch type {
            case .undefinedAttributeType:
                return nil
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
                return nil
            @unknown default:
                return nil
        }
    }
}
#endif
