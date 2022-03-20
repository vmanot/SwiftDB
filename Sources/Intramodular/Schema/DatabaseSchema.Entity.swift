//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension DatabaseSchema {
    public struct Entity: Codable, Hashable, @unchecked Sendable {
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
            self.subentities = subentities
            self.properties = properties
        }
    }
}

// MARK: - Conformances -

extension DatabaseSchema.Entity: Comparable {
    public static func < (lhs: DatabaseSchema.Entity, rhs: DatabaseSchema.Entity) -> Bool {
        lhs.name < rhs.name
    }
}
