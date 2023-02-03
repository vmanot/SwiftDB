//
// Copyright (c) Vatsal Manot
//

import Compute
import CorePersistence
import Foundation
import Swallow

extension _Schema {
    public final class Entity: _Schema.Record, @unchecked Sendable {
        public var parent: _Schema.Entity.ID?
        public var persistentTypeRepresentation: _SerializedTypeIdentity
        public var subentities: [_Schema.Entity]
        public var properties: [_Schema.Entity.Property]
        
        public init(
            parent: _Schema.Entity.ID?,
            name: String,
            persistentTypeRepresentation: _SerializedTypeIdentity,
            subentities: [_Schema.Entity],
            properties: [_Schema.Entity.Property]
        ) {
            self.parent = parent
            self.persistentTypeRepresentation = persistentTypeRepresentation
            self.subentities = subentities.sorted(by: \.name)
            self.properties = properties.sorted(by: \.name)
            
            super.init(type: .entity, name: name)
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder._polymorphic().container(keyedBy: CodingKeys.self)
            
            self.parent = try container.decode(forKey: .parent)
            self.persistentTypeRepresentation = try container.decode(forKey: .persistentTypeRepresentation)
            self.subentities = try container.decode(forKey: .subentities)
            self.properties = try container.decode(forKey: .properties)
            
            try super.init(from: decoder)
        }
        
        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(parent, forKey: .parent)
            try container.encode(name, forKey: .name)
            try container.encode(persistentTypeRepresentation, forKey: .persistentTypeRepresentation)
            try container.encode(subentities, forKey: .subentities)
            try container.encode(properties, forKey: .properties)
        }
        
        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            
            hasher.combine(parent)
            hasher.combine(name)
            hasher.combine(persistentTypeRepresentation)
            hasher.combine(subentities)
            hasher.combine(properties)
        }
    }
}

// MARK: - Extensions -

extension _Schema.Entity {
    private enum CodingKeys: String, CodingKey {
        case parent
        case name
        case persistentTypeRepresentation
        case subentities
        case properties
    }
}

extension _Schema.Entity {
    public var attributes: [_Schema.Entity.Attribute] {
        properties.compactMap({ $0 as? _Schema.Entity.Attribute })
    }
    
    public var relationships: [_Schema.Entity.Relationship] {
        properties.compactMap({ $0 as? _Schema.Entity.Relationship })
    }
    
    public func property(named name: String) throws -> _Schema.Entity.Property {
        try properties.first(where: { $0.name == name }).unwrap()
    }
    
    public func attribute(named name: String) throws -> _Schema.Entity.Attribute {
        try attributes.first(where: { $0.name == name }).unwrap()
    }
    
    public func relationship(named name: String) throws -> _Schema.Entity.Relationship {
        try relationships.first(where: { $0.name == name }).unwrap()
    }
}

// MARK: - Conformances -

extension _Schema.Entity: Identifiable {
    public enum ID: Codable, Hashable, Sendable {
        case autogenerated(String)
        case persistentTypeRepresentation(String)
        case unavailable
        
        public init(from entityType: any Entity.Type) throws {
            self = .autogenerated(String(describing: entityType))
        }
        
        public init(from type: Any.Type) throws {
            try self.init(from: try cast(type, to: any Entity.Type.self))
        }
    }
    
    public var id: ID {
        .autogenerated(name)
    }
}

extension _Schema.Entity: KeyedValuesOfConstructible {
    public convenience init(from values: KeyedValuesOf<_Schema.Entity>) throws {
        self.init(
            parent: try values.value(for: \.parent),
            name: try values.value(for: \.name),
            persistentTypeRepresentation: try values.value(for: \.persistentTypeRepresentation),
            subentities: try values.value(for: \.subentities),
            properties: try values.value(for: \.properties)
        )
    }
}
