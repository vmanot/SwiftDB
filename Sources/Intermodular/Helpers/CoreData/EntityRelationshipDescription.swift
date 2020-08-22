//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Runtime
import Swift

public final class EntityRelationshipDescription: EntityPropertyDescription {
    public enum CodingKeys: String, CodingKey {
        case destinationEntityName
        case inverseRelationshipName
        case cardinality
        case deleteRule
    }
    
    let destinationEntityName: String
    let inverseRelationshipName: String?
    let cardinality: EntityRelationshipCardinality
    let deleteRule: NSDeleteRule?
    let isOrdered: Bool = true
    
    public init(
        name: String,
        isOptional: Bool,
        isTransient: Bool,
        destinationEntityName: String,
        inverseRelationshipName: String?,
        cardinality: EntityRelationshipCardinality,
        deleteRule: NSDeleteRule?
    ) {
        self.destinationEntityName = destinationEntityName
        self.inverseRelationshipName = inverseRelationshipName
        self.cardinality = cardinality
        self.deleteRule = deleteRule
        
        super.init(name: name, isOptional: isOptional, isTransient: isTransient)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
        
        // try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        fatalError()
    }
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        
        hasher.combine(destinationEntityName)
        hasher.combine(inverseRelationshipName)
        hasher.combine(cardinality)
        hasher.combine(deleteRule)
    }
    
    public override func toNSPropertyDescription() -> NSPropertyDescription {
        NSRelationshipDescription(self)
    }
}

// MARK: - Auxiliary Implementation -

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
    
    convenience init(_ description: EntityRelationshipDescription) {
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

