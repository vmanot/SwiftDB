//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Runtime
import Swift

extension DatabaseSchema.Entity {
    public final class Relationship: DatabaseSchema.Entity.Property {
        public enum CodingKeys: String, CodingKey {
            case destinationEntityName
            case inverseRelationshipName
            case cardinality
            case deleteRule
            case isOrdered
        }
        
        let destinationEntityName: String
        let inverseRelationshipName: String?
        let cardinality: EntityRelationshipCardinality
        let deleteRule: NSDeleteRule?
        let isOrdered: Bool
        
        public init(
            name: String,
            isOptional: Bool,
            isTransient: Bool,
            renamingIdentifier: String?,
            destinationEntityName: String,
            inverseRelationshipName: String?,
            cardinality: EntityRelationshipCardinality,
            deleteRule: NSDeleteRule?,
            isOrdered: Bool
        ) {
            self.destinationEntityName = destinationEntityName
            self.inverseRelationshipName = inverseRelationshipName
            self.cardinality = cardinality
            self.deleteRule = deleteRule
            self.isOrdered = isOrdered
            
            super.init(
                name: name,
                isOptional: isOptional,
                isTransient: isTransient,
                renamingIdentifier: renamingIdentifier
            )
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            destinationEntityName = try container.decode(forKey: .destinationEntityName)
            inverseRelationshipName = try container.decode(forKey: .inverseRelationshipName)
            cardinality = try container.decode(forKey: .cardinality)
            deleteRule = try container.decode(forKey: .deleteRule)
            isOrdered = try container.decode(forKey: .isOrdered)
            
            try super.init(from: decoder)
        }
        
        public override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(destinationEntityName, forKey: .destinationEntityName)
            try container.encode(inverseRelationshipName, forKey: .inverseRelationshipName)
            try container.encode(cardinality, forKey: .cardinality)
            try container.encode(deleteRule, forKey: .deleteRule)
            try container.encode(isOrdered, forKey: .isOrdered)
        }
        
        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            
            hasher.combine(destinationEntityName)
            hasher.combine(inverseRelationshipName)
            hasher.combine(cardinality)
            hasher.combine(deleteRule)
            hasher.combine(isOrdered)
        }
    }
}
