//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swallow

extension DatabaseSchema {
    public struct Entity: Codable, Hashable {
        @Indirect
        public var parent: DatabaseSchema.Entity?
        public let name: String
        public let managedObjectClassName: String
        public let subentities: MaybeKnown<[Self]>
        public let properties: [DatabaseSchema.Entity.Property]
        
        public init(
            parent: DatabaseSchema.Entity?,
            name: String,
            managedObjectClassName: String,
            subentities: MaybeKnown<[Self]>,
            properties: [DatabaseSchema.Entity.Property]
        ) {
            self.parent = parent
            self.name = name
            self.managedObjectClassName = managedObjectClassName
            self.subentities = subentities
            self.properties = properties
        }
    }
}
