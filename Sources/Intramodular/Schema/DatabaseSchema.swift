//
// Copyright (c) Vatsal Manot
//

import Compute
import CoreData
import Runtime
import Swallow
import SwiftUI

/// A type-erased description of a `Schema`.
public struct DatabaseSchema: Codable, Hashable {
    public let entities: [Entity]
    
    @usableFromInline
    @TransientProperty
    var entityNameToTypeMap = BidirectionalMap<String,  Metatype<_opaque_Entity.Type>>()
    @usableFromInline
    @TransientProperty
    var entityToTypeMap = BidirectionalMap<Entity,  Metatype<_opaque_Entity.Type>>()
    
    @inlinable
    public init(_ schema: Schema) {
        self.entities = schema.body.map({ .init($0) })
        
        for (entity, entityType) in entities.zip(schema.body) {
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
