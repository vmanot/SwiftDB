//
// Copyright (c) Vatsal Manot
//

import Compute
import CoreData
import Runtime
import Swallow
import SwiftUI

/// A type-erased description of a `Schema`.
public struct DatabaseSchema: Codable, Hashable, Named {
    @usableFromInline
    var _runtime: _Runtime {
        .default
    }
    
    public let name: String
    public let entities: [Entity]
    
    @usableFromInline
    @TransientProperty
    var entityNameToTypeMap = BidirectionalMap<String,  Metatype<_opaque_Entity.Type>>()
    @usableFromInline
    @TransientProperty
    var entityToTypeMap = BidirectionalMap<Entity,  Metatype<_opaque_Entity.Type>>()
    
    @inlinable
    public init(_ schema: Schema) {
        self.name = schema.name
        self.entities = schema.body.map({ $0.toEntityDescription() })
        
        for (entity, entityType) in entities.zip(schema.body) {
            _runtime.typeCache.entity[entity.name] = .init(entityType)
            entityNameToTypeMap[entity.name] = .init(entityType)
            entityToTypeMap[entity] = .init(entityType)
        }
    }
}

// MARK: - Auxiliary Implementation -

extension NSManagedObject {
    var _SwiftDB_databaseSchema: DatabaseSchema? {
        managedObjectContext?.persistentStoreCoordinator?._SwiftDB_databaseSchema
    }
}
