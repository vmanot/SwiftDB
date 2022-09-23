//
// Copyright (c) Vatsal Manot
//

import Compute
import Runtime
import Swallow
import SwiftUI

public protocol KeyPathIterable {
    static var keyPaths: [PartialKeyPath<Self>] { get }
}

public struct EntityID: KeyPathIterable {
    public let name: String
    public let className: String?
    public let persistentTypeIdentifier: String
    
    public static var keyPaths: [PartialKeyPath<Self>] {
        [\.name, \.className, \.persistentTypeIdentifier]
    }
}

/// A type-erased description of a `Schema`.
public struct DatabaseSchema:  Hashable, Sendable, Versioned {
    public var version: Version? = "0.0.1"
    
    public let entities: IdentifierIndexedArray<Entity, Entity.ID>
    
    var entityNameToTypeMap = BidirectionalMap<String,  Metatype<_opaque_Entity.Type>>()
    var entityToTypeMap = BidirectionalMap<Entity, Metatype<_opaque_Entity.Type>>()
    
    public init(entities: [Entity: Metatype<_opaque_Entity.Type>]) {
        self.entities = .init(entities.keys.sorted())
        
        for (entity, entityType) in entities {
            entityNameToTypeMap[entity.name] = .init(entityType)
            entityToTypeMap[entity] = .init(entityType)
        }
    }
    
    public init(_ schema: Schema) throws {
        let metatypesByEntity = Dictionary(
            try schema
                .body
                .map({ try Entity(from: $0) })
                .zip(schema.body.lazy.map({ Metatype($0) }))
                .lazy
                .map({ (key: $0.0, value: $0.1) })
        )
        
        let entitiesByID: [DatabaseSchema.Entity.ID: [DatabaseSchema.Entity]] = metatypesByEntity.keys.group(by: \.id)
        var entitySubentityRelationshipsByID: [DatabaseSchema.Entity.ID: Set<DatabaseSchema.Entity.ID>] = [:]
        
        for (id, possiblyDuplicatedEntities) in entitiesByID {
            entitySubentityRelationshipsByID[id] ??= []
            
            for entity in possiblyDuplicatedEntities {
                if let parentEntityID = entity.parent?.id {
                    entitySubentityRelationshipsByID[parentEntityID, default: []].insert(entity.id)
                }
            }
        }
        
        self.init(entities: metatypesByEntity)
    }
    
    func entity<Model>(forModelType modelType: Model.Type) -> Entity? {
        guard let type = modelType as? _opaque_Entity.Type else {
            return nil
        }
        
        return entityToTypeMap[Metatype(type)]
    }
}

public struct TreeParentChildRelationshipsByID<ID> {
    public init(ids: [ID]) {
        
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

// MARK: - Helpers -

extension DatabaseSchema.Entity {
    fileprivate init(from type: _opaque_Entity.Type) throws {
        let instance = try type.init(_underlyingDatabaseRecord: nil)
        
        self.init(
            parent: try type._opaque_ParentEntity.map { parentType in
                try DatabaseSchema.Entity(from: parentType)
            },
            name: type.name,
            className: type.underlyingDatabaseRecordClass.name,
            subentities: .unknown,
            properties: try instance._runtime_propertyAccessors.map({ try $0.schema() })
        )
    }
}
