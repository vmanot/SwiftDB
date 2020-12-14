//
// Copyright (c) Vatsal Manot
//

import Swallow
import Task

/// A (user-definable) key for describing the set of supported database capabilities.
public struct DatabaseCapability: Codable, Hashable, RawRepresentable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
