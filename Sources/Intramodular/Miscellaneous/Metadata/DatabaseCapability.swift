//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A (user-definable) key for describing the set of supported database capabilities.
public struct DatabaseCapability: Codable, Hashable, RawRepresentable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension DatabaseCapability {
    public static let schemaless = Self(rawValue: "schemaless")
    public static let schemafull = Self(rawValue: "schemafull")
    public static let relationships = Self(rawValue: "relationships")
}
