//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Runtime
import Swift

extension DatabaseSchema.Entity {
    public struct RelationshipConfiguration: Codable, Hashable {
        let destinationEntityName: String
        let inverseRelationshipName: String?
        let cardinality: DatabaseSchema.Entity.Relationship.Cardinality
        let deleteRule: NSDeleteRule?
        let isOrdered: Bool
    }
    
    public final class Relationship: DatabaseSchema.Entity.Property {
        private enum CodingKeys: String, CodingKey {
            case relationshipConfiguration
        }
        
        public let relationshipConfiguration: RelationshipConfiguration
        
        public init(
            name: String,
            propertyConfiguration: PropertyConfiguration,
            relationshipConfiguration: RelationshipConfiguration
        ) {
            self.relationshipConfiguration = relationshipConfiguration
            
            super.init(
                name: name,
                propertyConfiguration: propertyConfiguration
            )
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            relationshipConfiguration = try container.decode(forKey: .relationshipConfiguration)

            try super.init(from: decoder)
        }
        
        public override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(relationshipConfiguration, forKey: .relationshipConfiguration)
        }
        
        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            
            hasher.combine(relationshipConfiguration)
        }
    }
}

extension DatabaseSchema.Entity.Relationship {
    public enum EntityCardinality {
        case one
        case many
    }
    
    public enum Cardinality: Codable, CustomStringConvertible {
        case oneToOne
        case oneToMany
        case manyToOne
        case manyToMany
        
        public var description: String {
            switch self {
                case .oneToOne:
                    return "one-to-one"
                case .oneToMany:
                    return "one-to-many"
                case .manyToOne:
                    return "many-to-one"
                case .manyToMany:
                    return "many-to-many"
            }
        }
        
        public init(source: EntityCardinality, destination: EntityCardinality) {
            switch (source, destination) {
                case (.one, .one):
                    self = .oneToOne
                case (.one, .many):
                    self = .oneToMany
                case (.many, .one):
                    self = .oneToMany
                case (.many, .many):
                    self = .manyToMany
            }
        }
    }
}
