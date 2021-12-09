//
// Copyright (c) Vatsal Manot
//

import Compute
import Runtime
import Swallow
import SwiftUI

/// A type-erased description of a `Schema`.
public struct DatabaseSchema: Codable, Hashable {
    public enum CodingKeys: String, CodingKey {
        case entities
    }
    
    public let entities: [Entity]
    
    @usableFromInline
    var entityNameToTypeMap = BidirectionalMap<String,  Metatype<_opaque_Entity.Type>>()
    @usableFromInline
    var entityToTypeMap = BidirectionalMap<Entity, Metatype<_opaque_Entity.Type>>()
    
    public init(entities: [Entity: Metatype<_opaque_Entity.Type>]) {
        self.entities = Array(entities.keys.sorted())
        
        for (entity, entityType) in entities {
            entityNameToTypeMap[entity.name] = .init(entityType)
            entityToTypeMap[entity] = .init(entityType)
        }
    }
    
    func entity<Model>(forModelType modelType: Model.Type) -> Entity? {
        guard let type = modelType as? _opaque_Entity.Type else {
            return nil
        }
        
        return entityToTypeMap[Metatype(type)]
    }
}

extension DatabaseSchema {
    @inlinable
    public init(_ schema: Schema) throws {
        self.init(
            entities: Dictionary(
                try schema
                    .body
                    .map({ try Entity($0) })
                    .zip(schema.body.lazy.map({ Metatype($0) }))
                    .lazy
                    .map({ (key: $0.0, value: $0.1) })
            )
        )
    }
}
