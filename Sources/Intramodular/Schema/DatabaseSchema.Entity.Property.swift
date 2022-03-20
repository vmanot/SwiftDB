//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

extension DatabaseSchema.Entity {
    public struct PropertyConfiguration: Codable, Hashable, Sendable {
        public var isOptional: Bool?
        public var isTransient: Bool = false
        public var renamingIdentifier: String?
    }
    
    public class Property: Codable, Hashable, Model, @unchecked Sendable {
        fileprivate enum CodingKeys: String, CodingKey {
            case name
            case propertyConfiguration
        }
        
        public static let version: Version? = "0.0.0"
        
        public let name: String
        public let propertyConfiguration: PropertyConfiguration
        
        public init(
            name: String,
            propertyConfiguration: PropertyConfiguration
        ) {
            self.name = name
            self.propertyConfiguration = propertyConfiguration
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try container.decode(forKey: .name)
            self.propertyConfiguration = try container.decode(forKey: .propertyConfiguration)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(name, forKey: .name)
            try container.encode(propertyConfiguration, forKey: .propertyConfiguration)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(propertyConfiguration)
        }
    }
}

// MARK: - Implementations -

extension DatabaseSchema.Entity.Property: Comparable {
    public static func < (lhs: DatabaseSchema.Entity.Property, rhs: DatabaseSchema.Entity.Property) -> Bool {
        (lhs.propertyConfiguration.renamingIdentifier ?? lhs.name) < (rhs.propertyConfiguration.renamingIdentifier ?? rhs.name)
    }
}

extension DatabaseSchema.Entity.Property: Equatable {
    public static func == (lhs: DatabaseSchema.Entity.Property, rhs: DatabaseSchema.Entity.Property) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
