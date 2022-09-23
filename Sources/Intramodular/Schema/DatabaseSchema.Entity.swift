//
// Copyright (c) Vatsal Manot
//

import Compute
import Foundation
import Swallow

extension DatabaseSchema {
    public struct Entity: @unchecked Sendable {
        public enum ID: Codable, Hashable, Sendable {
            case name(String)
            case persistentTypeIdentifier(String)
            case unavailable
        }
        
        @Indirect
        public var parent: DatabaseSchema.Entity?
        public let name: String
        public let className: String?
        public let subentities: MaybeKnown<[Self]>
        public let properties: [DatabaseSchema.Entity.Property]
        
        public init(
            parent: DatabaseSchema.Entity?,
            name: String,
            className: String?,
            subentities: MaybeKnown<[Self]>,
            properties: [DatabaseSchema.Entity.Property]
        ) {
            self.parent = parent
            self.name = name
            self.className = className
            self.subentities = subentities.map({ $0.sorted(by: \.name) })
            self.properties = properties.sorted(by: \.name)
        }
    }
}

// MARK: - Extensions -

extension DatabaseSchema.Entity: Codable {
    public enum CodingKeys: String, CodingKey {
        case parent
        case name
        case className
        case subentities
        case properties
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.polymorphic().container(keyedBy: CodingKeys.self)
        
        self.parent = try container.decode(forKey: .parent)
        self.name = try container.decode(forKey: .name)
        self.className = try container.decode(forKey: .className)
        self.subentities = try container.decode(forKey: .subentities)
        self.properties = try container.decode(forKey: .properties)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(parent, forKey: .parent)
        try container.encode(name, forKey: .name)
        try container.encode(className, forKey: .className)
        try container.encode(subentities, forKey: .subentities)
        try container.encode(properties, forKey: .properties)
    }
}

extension DatabaseSchema.Entity {
    public var attributes: [DatabaseSchema.Entity.Attribute] {
        properties.compactMap({ $0 as? DatabaseSchema.Entity.Attribute })
    }

    public var relationships: [DatabaseSchema.Entity.Relationship] {
        properties.compactMap({ $0 as? DatabaseSchema.Entity.Relationship })
    }
}

// MARK: - Conformances -

extension DatabaseSchema.Entity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(className)
        hasher.combine(properties)
    }
}

extension DatabaseSchema.Entity: Identifiable {
    public var id: ID {
        .name(name)
    }
}

extension DatabaseSchema.Entity: Comparable {
    public static func < (lhs: DatabaseSchema.Entity, rhs: DatabaseSchema.Entity) -> Bool {
        lhs.name < rhs.name
    }
}

/*extension DatabaseSchema.Entity: ManagedTreeNode {
    public var children: [DatabaseSchema.Entity] {
        subentities.knownValue
    }
}
*/
