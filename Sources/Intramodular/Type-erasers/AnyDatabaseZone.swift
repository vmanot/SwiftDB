//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type-erased wrapper for a database zone.
public struct AnyDatabaseZone: DatabaseZone {
    let base: any DatabaseZone
    
    public var id: ID {
        ID(erasing: base._opaque_zoneID)
    }
    
    init<T: DatabaseZone>(base zone: T) {
        self.base = zone
    }
}

// MARK: - Auxiliary

extension AnyDatabaseZone {
    public struct ID: Codable, Hashable {
        let base: Codable & Encodable
        
        private let hashImpl: (inout Hasher) -> Void
        
        init<ID: Codable & Hashable>(erasing id: ID) {
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

fileprivate extension DatabaseZone {
    var _opaque_zoneID: AnyDatabaseZone.ID {
        .init(erasing: id)
    }
}
