//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

public class EntityPropertyDescription: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case name
        case isOptional
        case isTransient
    }
    
    public private(set) var name: String
    public private(set) var isOptional: Bool = false
    public private(set) var isTransient: Bool = false
    
    public init(
        name: String,
        isOptional: Bool,
        isTransient: Bool
    ) {
        self.name = name
        self.isOptional = isOptional
        self.isTransient = isTransient
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.isOptional = try container.decode(Bool.self, forKey: .isOptional)
        self.isTransient = try container.decode(Bool.self, forKey: .isTransient)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(isOptional, forKey: .isOptional)
        try container.encode(isTransient, forKey: .isTransient)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(isOptional)
        hasher.combine(isTransient)
    }

    public func toNSPropertyDescription() -> NSPropertyDescription {
        Never.materialize(reason: .abstract)
    }
}

extension EntityPropertyDescription {
    public static func == (lhs: EntityPropertyDescription, rhs: EntityPropertyDescription) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
