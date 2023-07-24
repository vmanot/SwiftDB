//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Runtime
import Swift

extension _Schema.Entity {
    public struct RelationshipConfiguration: Codable, Hashable {
        public var traits: [EntityRelationshipTrait]
        public var destinationEntity: _Schema.Entity.ID?
        public var inverseRelationshipName: String?
        public var cardinality: _Schema.Entity.Relationship.Cardinality
        public var deleteRule: NSDeleteRule?
        public var isOrdered: Bool
    }
    
    public final class Relationship: _Schema.Entity.Property {
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
                type: .relationship,
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
            try super.encode(to: encoder)
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(relationshipConfiguration, forKey: .relationshipConfiguration)
        }
        
        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            
            hasher.combine(relationshipConfiguration)
        }
    }
}

extension _Schema.Entity.Relationship {
    public enum EntityCardinality {
        case one
        case many
    }
    
    public enum Cardinality: String, Codable, CustomStringConvertible {
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
        
        public var inverse: Self {
            switch self {
                case .oneToOne:
                    return .oneToOne
                case .oneToMany:
                    return .manyToOne
                case .manyToOne:
                    return .oneToMany
                case .manyToMany:
                    return .manyToMany
            }
        }
        
        public init(source: EntityCardinality, destination: EntityCardinality) {
            switch (source, destination) {
                case (.one, .one):
                    self = .oneToOne
                case (.one, .many):
                    self = .oneToMany
                case (.many, .one):
                    self = .manyToOne
                case (.many, .many):
                    self = .manyToMany
            }
        }
    }
}

// MARK: - Supplementary

extension DatabaseRecordRelationshipType {
    /// The record relationship type relative to the destination of the given relationship property.
    static func destinationType(
        from relationship: _Schema.Entity.Relationship
    ) -> Self {
        let isOrdered = relationship.relationshipConfiguration.isOrdered
        
        switch relationship.relationshipConfiguration.cardinality {
            case .oneToOne:
                return .toOne
            case .oneToMany:
                return isOrdered ? .toOrderedMany : .toUnorderedMany
            case .manyToOne:
                return .toOne
            case .manyToMany:
                return isOrdered ? .toOrderedMany : .toUnorderedMany // FIXME?
        }
    }
}
