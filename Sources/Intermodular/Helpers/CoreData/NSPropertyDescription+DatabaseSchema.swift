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
    public convenience init(_ description: DatabaseSchema.Entity.Attribute) {
        self.init()
        
        name = description.name
        isOptional = description.isOptional
        isTransient = description.isTransient
        attributeType = .init(description.type)
        
        if let attributeValueClassName = description.type.className {
            self.attributeValueClassName = attributeValueClassName
        }
        
        if let valueTransformerName = description.type.transformerName {
            self.valueTransformerName = valueTransformerName
        }
        
        allowsExternalBinaryDataStorage = description.allowsExternalBinaryDataStorage
        preservesValueInHistoryOnDeletion = description.preservesValueInHistoryOnDeletion
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
    
    convenience init(_ description: DatabaseSchema.Entity.Relationship) {
        self.init()
        
        name = description.name
        isOptional = description.isOptional
        isTransient = description.isTransient
        
        destinationEntityName = description.destinationEntityName
        inverseRelationshipName = description.inverseRelationshipName
        
        switch description.cardinality {
            case .oneToOne:
                minCount = description.isOptional ? 0 : 1
                maxCount = 1
            case .oneToMany:
                minCount = 0
                maxCount = 0
            case .manyToOne:
                minCount = description.isOptional ? 0 : 1
                maxCount = 1
            case .manyToMany:
                minCount = 0
                maxCount = 0
        }
        
        if let deleteRule = description.deleteRule {
            self.deleteRule = deleteRule
        }
    }
}
