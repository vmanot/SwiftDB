//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swift

extension DatabaseSchema.Entity {
    public class Property: Codable, Hashable, Model {
        public static let version: Version? = "0.0.0"
        
        fileprivate enum CodingKeys: String, CodingKey {
            case name
            case isOptional
            case isTransient
            case renamingIdentifier
        }
        
        public let name: String
        public let isOptional: Bool
        public let isTransient: Bool
        public let renamingIdentifier: String?
        
        public init(
            name: String,
            isOptional: Bool,
            isTransient: Bool,
            renamingIdentifier: String?
        ) {
            self.name = name
            self.isOptional = isOptional
            self.isTransient = isTransient
            self.renamingIdentifier = renamingIdentifier
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try container.decode(forKey: .name)
            self.isOptional = try container.decode(forKey: .isOptional)
            self.isTransient = try container.decode(forKey: .isTransient)
            self.renamingIdentifier = try container.decodeIfPresent(forKey: .renamingIdentifier)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(name, forKey: .name)
            try container.encode(isOptional, forKey: .isOptional)
            try container.encode(isTransient, forKey: .isTransient)
            try container.encode(renamingIdentifier, forKey: .renamingIdentifier)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(isOptional)
            hasher.combine(isTransient)
            hasher.combine(renamingIdentifier)
        }
    }
}

// MARK: - Protocol Conformances -

extension DatabaseSchema.Entity.Property: Comparable {
    public static func < (lhs: DatabaseSchema.Entity.Property, rhs: DatabaseSchema.Entity.Property) -> Bool {
        (lhs.renamingIdentifier ?? lhs.name) < (rhs.renamingIdentifier ?? rhs.name)
    }
}

extension DatabaseSchema.Entity.Property: Equatable {
    public static func == (lhs: DatabaseSchema.Entity.Property, rhs: DatabaseSchema.Entity.Property) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
