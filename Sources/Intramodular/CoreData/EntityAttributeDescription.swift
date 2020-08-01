//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swift

public struct EntityAttributeDescription: EntityPropertyDescription {
    public private(set) var name: String
    public private(set) var isOptional: Bool = false
    public private(set) var isTransient: Bool = false
    public private(set) var type: EntityAttributeTypeDescription = .undefined
    public private(set) var allowsExternalBinaryDataStorage: Bool = false
    public private(set) var preservesValueInHistoryOnDeletion: Bool = false
    
    public init(name: String) {
        self.name = name
    }
    
    public func toNSPropertyDescription() -> NSPropertyDescription {
        NSAttributeDescription(self)
    }
}

extension EntityAttributeDescription {
    public func `type`(_ value: EntityAttributeTypeDescription)-> Self {
        var result = self
        
        result.type = value
        
        return result
    }
    
    public func optional(_ value: Bool)-> Self {
        var result = self
        
        result.isOptional = value
        
        return result
    }
    
    public func transient(_ value: Bool)-> Self {
        var result = self
        
        result.isTransient = value
        
        return result
    }
    
    public func allowsExternalBinaryDataStorage(_ value: Bool)-> Self {
        var result = self
        
        result.allowsExternalBinaryDataStorage = value
        
        return result
    }
    
    public func preservesValueInHistoryOnDeletion(_ value: Bool)-> Self {
        var result = self
        
        result.preservesValueInHistoryOnDeletion = value
        
        return result
    }
}

// MARK: - Auxiliary Implementation -

extension NSAttributeDescription {
    public convenience init(_ description: EntityAttributeDescription) {
        self.init()
        
        name = description.name
        isOptional = description.isOptional
        isTransient = description.isTransient
        
        switch description.type {
            case .undefined:
                attributeType = .undefinedAttributeType
            case .integer16:
                attributeType = .integer16AttributeType
            case .integer32:
                attributeType = .integer32AttributeType
            case .integer64:
                attributeType = .integer64AttributeType
            case .decimal:
                attributeType = .decimalAttributeType
            case .double:
                attributeType = .doubleAttributeType
            case .float:
                attributeType = .floatAttributeType
            case .string:
                attributeType = .stringAttributeType
            case .boolean:
                attributeType = .booleanAttributeType
            case .date:
                attributeType = .dateAttributeType
            case .binaryData:
                attributeType = .binaryDataAttributeType
            case .UUID:
                attributeType = .UUIDAttributeType
            case .URI:
                attributeType = .URIAttributeType
            case let .transformable(className, transformerName):
                attributeType = .transformableAttributeType
                attributeValueClassName = className
                valueTransformerName = transformerName
            case .objectID:
                attributeType = .objectIDAttributeType
        }
        
        allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
    }
}
