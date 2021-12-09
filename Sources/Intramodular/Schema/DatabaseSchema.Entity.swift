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

// MARK: - Protocol Conformances -

extension DatabaseSchema.Entity: Comparable {
    public static func < (lhs: DatabaseSchema.Entity, rhs: DatabaseSchema.Entity) -> Bool {
        lhs.name < rhs.name
    }
}

// MARK: - Auxiliary Implementation -

extension DatabaseSchema.Entity {
    public init(_ type: _opaque_Entity.Type) throws {
        let instance = try type.init(
            _underlyingDatabaseRecord: nil
        )
        
        self.init(
            parent: try type._opaque_ParentEntity.map(DatabaseSchema.Entity.init),
            name: type.name,
            className: type.underlyingDatabaseRecordClass.name,
            subentities: .unknown,
            properties: try instance._runtime_propertyAccessors.map({ try $0.schema() })
        )
    }
}
