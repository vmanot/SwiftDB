//
// Copyright (c) Vatsal Manot
//

import Compute
import FoundationX
import Runtime
import Swallow
import SwiftUI

/// A type-erased description of a `Schema`.
public struct _Schema: Hashable, Sendable, Versioned {
    public var version: Version? = "0.0.1"
    
    public let entities: IdentifierIndexedArray<Entity, Entity.ID>
    
    private var entityTypesByName = BidirectionalMap<String,  Metatype<any SwiftDB.Entity.Type>>()
    private var entityTypesByEntityID = BidirectionalMap<Entity.ID, Metatype<any SwiftDB.Entity.Type>>()
    
    public init(entities: [_Schema.Entity]) throws {
        self.entities = .init(entities.sorted(by: \.name))
        
        for entity in entities {
            let metatype = Metatype(try cast(entity.persistentTypeRepresentation.resolveType(), to: (any SwiftDB.Entity.Type).self))
            
            entityTypesByName[entity.name] = metatype
            entityTypesByEntityID[entity.id] = metatype
        }
    }
    
    public init(_ schema: Schema) throws {
        let partialEntitiesByID = Dictionary(
            try schema.body.map { (entityType: any SwiftDB.Entity.Type) in
                let key = try _Schema.Entity.ID(from: entityType)
                let value = try KeyedValuesOf<_Schema.Entity>(from: entityType)
                
                return (key, value)
            },
            uniquingKeysWith: { lhs, rhs in
                lhs
            }
        )
        
        var entitySubentityRelationshipsByID: [_Schema.Entity.ID: Set<_Schema.Entity.ID>] = [:]
        
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
    
    public subscript(_ entityID: _Schema.Entity.ID) -> _Schema.Entity? {
        entities[id: entityID]
    }
    
    func entity(forModelType modelType: Any.Type) throws -> Entity? {
        guard let type = modelType as? any SwiftDB.Entity.Type else {
            throw Error.failedToMapModelTypeToEntity(modelType: modelType)
        }
        
        guard let entityID = entityTypesByEntityID[Metatype(type)] else {
            throw Error.failedToMapModelTypeToEntity(modelType: modelType)
        }
        
        return self[entityID]
    }
    
    func record(forModelType modelType: Any.Type) throws -> _Schema.Record? {
        try entity(forModelType: modelType) // FIXME
    }
    
    func entityType(for entity: Entity.ID) throws -> any (SwiftDB.Entity).Type {
        do {
            return try cast(try entityTypesByEntityID[entity].unwrap().value)
        } catch {
            throw Error.failedToResolveEntityTypeForID(entity)
        }
    }
    
    func entity(withName name: String) throws -> Entity {
        try entities.first(where: { $0.name == name }).unwrap()
    }
}

// MARK: - Conformances

extension _Schema: Codable {
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


// MARK: - Auxiliary

extension _Schema {
    private enum Error: Swift.Error {
        case failedToResolveEntityTypeForID(Entity.ID)
        case failedToMapModelTypeToEntity(modelType: Any.Type)
    }
}

fileprivate extension KeyedValuesOf where Wrapped == _Schema.Entity {
    /// Extracts values required to construct an entity schema from an entity type.
    init(from type: any Entity.Type) throws {
        // Create an uninitialized instance.
        let instance = try type.init(_databaseRecordProxy: nil)
        
        self.init()
        
        self.parent = try type._opaque_ParentEntity.map({ parentType in try _Schema.Entity.ID(from: parentType) })
        self.name = String(describing: type)
        self.persistentTypeRepresentation = .init(from: type)
        self.properties = try instance._runtime_propertyAccessors.map({ try $0.schema() })
    }
}
