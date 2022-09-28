//
// Copyright (c) Vatsal Manot
//

import Compute
import Runtime
import Swallow
import SwiftUI

/// A type-erased description of a `Schema`.
public struct DatabaseSchema: Hashable, Sendable, Versioned {
    public var version: Version? = "0.0.1"
    
    public let entities: IdentifierIndexedArray<Entity, Entity.ID>
    
    private var entityTypesByName = BidirectionalMap<String,  Metatype<any SwiftDB.Entity.Type>>()
    private var entityTypesByEntityID = BidirectionalMap<Entity.ID, Metatype<any SwiftDB.Entity.Type>>()
    
    public init(entities: [DatabaseSchema.Entity]) throws {
        self.entities = .init(entities.sorted(by: \.name))
        
        for entity in entities {
            let metatype = Metatype(try cast(entity.typeIdentity.resolveType(), to: any SwiftDB.Entity.Type.self))
            
            entityTypesByName[entity.name] = metatype
            entityTypesByEntityID[entity.id] = metatype
        }
    }
    
    public init(_ schema: Schema) throws {
        let partialEntitiesByID = Dictionary(try schema.body.map({ (key: try Entity.ID(from: $0), value: try KeyedValuesOf<Entity>(from: $0)) }), uniquingKeysWith: { lhs, rhs in lhs })
        
        var entitySubentityRelationshipsByID: [DatabaseSchema.Entity.ID: Set<DatabaseSchema.Entity.ID>] = [:]
        
        for (id, entity) in partialEntitiesByID {
            entitySubentityRelationshipsByID[id] ??= []
            
            if let parentEntityID = try entity.value(for: \.parent) {
                entitySubentityRelationshipsByID[parentEntityID, default: []].insert(id)
            }
        }
        
        // FIXME: Subentities are discarded. Need to create a directed graph from `entitySubentityRelationshipsByID` and traverse it (see https://stackoverflow.com/questions/45460653/given-a-flat-list-of-parent-child-create-a-hierarchical-dictionary-tree).
        
        let entities = try partialEntitiesByID.values.map({ partial in
            var partial = partial
            
            partial.subentities = [] // FIXME
            
            return try Entity(from: partial)
        })
        
        try self.init(entities: entities)
    }
    
    public subscript(_ entityID: DatabaseSchema.Entity.ID) -> DatabaseSchema.Entity? {
        entities[id: entityID]
    }
    
    func entity(forModelType modelType: Any.Type) -> Entity? {
        guard let type = modelType as? any SwiftDB.Entity.Type else {
            return nil
        }
        
        return entityTypesByEntityID[Metatype(type)].flatMap({ self[$0] })
    }
    
    func entityType(for entity: Entity.ID) throws -> any (SwiftDB.Entity).Type {
        do {
            return try cast(try entityTypesByEntityID[entity].unwrap().value)
        } catch {
            throw Error.failedToResolveEntityTypeForID(entity)
        }
    }
}

// MARK: - Conformances -

extension DatabaseSchema: Codable {
    enum CodingKeys: String, CodingKey {
        case version
        case entities
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.version = try container.decode(forKey: .version)
        self.entities = try container.decode(forKey: .entities)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(version, forKey: .version)
        try container.encode(entities, forKey: .entities)
    }
}


// MARK: - Auxiliary Implementation -

extension DatabaseSchema {
    private enum Error: Swift.Error {
        case failedToResolveEntityTypeForID(Entity.ID)
    }
}

fileprivate extension KeyedValuesOf where Wrapped == DatabaseSchema.Entity {
    /// Extracts values required to construct an entity schema from an entity type.
    init(from type: _opaque_Entity.Type) throws {
        // Create an uninitialized instance.
        let instance = try type.init(from: nil)
        
        self.init()
        
        self.parent = try type._opaque_ParentEntity.map({ parentType in try DatabaseSchema.Entity.ID(from: parentType) })
        self.name = String(describing: type)
        self.typeIdentity = .init(from: type)
        self.properties = try instance._runtime_propertyAccessors.map({ try $0.schema() })
    }
}
