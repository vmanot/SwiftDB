//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type-erased wrapper for a database zone.
public struct AnyDatabaseZone: DatabaseZone {
    let base: Any
    
    public let name: String
    public let id: Identifier
    
    init<T: DatabaseZone>(base zone: T) {
        self.base = zone
        
        self.name = zone.name
        self.id = Identifier(base: zone.id)
    }
}

extension AnyDatabaseZone {
    public struct Identifier: Codable, Hashable {
        let base: Any & Encodable
        
        private let hashImpl: (inout Hasher) -> Void
        
        init<ID: Codable & Hashable>(base id: ID) {
            self.base = id
            self.hashImpl = id.hash(into:)
        }
        
        public init(from decoder: Decoder) throws {
            throw Never.Reason.unsupported
        }
        
        public func encode(to encoder: Encoder) throws {
            try base.encode(to: encoder)
        }
        
        public func hash(into hasher: inout Hasher) {
            hashImpl(&hasher)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
