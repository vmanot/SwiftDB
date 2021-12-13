//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Runtime
import Swallow

extension AnyProtocol where Self: NSPropertyDescription {
    public init(from property: DatabaseSchema.Entity.Property) throws {
        switch property {
            case let attribute as DatabaseSchema.Entity.Attribute:
                self = try cast(NSAttributeDescription(attribute), to: Self.self)
            case let relationship as DatabaseSchema.Entity.Relationship:
                self = try cast(NSRelationshipDescription(relationship), to: Self.self)
            default:
                throw EmptyError()
        }
    }
}

extension NSAttributeDescription {
    public convenience init(_ description: DatabaseSchema.Entity.Attribute) throws {
        self.init()
        
        name = description.name
        isOptional = try description.propertyConfiguration.isOptional.unwrap()
        isTransient = description.propertyConfiguration.isTransient
        attributeType = .init(description.attributeConfiguration.type)
        
        if let attributeValueClassName = description.attributeConfiguration.type.className {
            self.attributeValueClassName = attributeValueClassName
        }
        
        if let valueTransformerName = description.attributeConfiguration.type.transformerName {
            self.valueTransformerName = valueTransformerName
        }
        
        allowsExternalBinaryDataStorage = description.attributeConfiguration.allowsExternalBinaryDataStorage
        preservesValueInHistoryOnDeletion = description.attributeConfiguration.preservesValueInHistoryOnDeletion
        
        defaultValue = description.attributeConfiguration.defaultValue?.cocoaObjectValue()
    }
}

extension NSRelationshipDescription {
    private static let destinationEntityNameKey = ObjCAssociationKey<String>()
    private static let inverseRelationshipName = ObjCAssociationKey<String>()
    
    var destinationEntityName: String? {
        get {
            self[Self.destinationEntityNameKey]
        } set {
            self[Self.destinationEntityNameKey] = newValue
        }
    }
    
    var inverseRelationshipName: String? {
        get {
            self[Self.inverseRelationshipName]
        } set {
            self[Self.inverseRelationshipName] = newValue
        }
    }
    
    convenience init(_ description: DatabaseSchema.Entity.Relationship) throws {
        self.init()
        
        name = description.name
        isOptional = try description.propertyConfiguration.isOptional.unwrap()
        isTransient = description.propertyConfiguration.isTransient
        
        destinationEntityName = description.relationshipConfiguration.destinationEntityName
        inverseRelationshipName = description.relationshipConfiguration.inverseRelationshipName
        
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

extension NSAttributeDescription {
    convenience init(_ attribute: _opaque_EntityPropertyAccessor) throws {
        try self.init(try cast(try attribute.schema(), to: DatabaseSchema.Entity.Attribute.self))
    }
}
