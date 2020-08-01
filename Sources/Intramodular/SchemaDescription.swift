//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

public struct SchemaDescription {
    public let entities: [EntityDescription]
    
    public init(
        @ArrayBuilder<opaque_Entity.Type> entities: () -> [opaque_Entity.Type]
    ) {
        var parentNameToChildrenMap: [String: [EntityDescription]] = [:]
        var nameToEntityMap: [String: EntityDescription] = [:]
        
        for entity in entities() {
            let description = entity.toEntityDescription()
            
            nameToEntityMap[entity.name] = description
            
            if let parent = entity.opaque_ParentType {
                parentNameToChildrenMap[parent.name, default: []].insert(description)
            }
        }
        
        for name in nameToEntityMap.keys {
            if let children = parentNameToChildrenMap[name] {
                nameToEntityMap[name]?.insertSubentities(children)
            }
        }
        
        self.entities = .init(nameToEntityMap.values)
    }
}

// MARK: - Auxiliary Implementation -

extension NSManagedObjectModel {
    public convenience init(_ schema: SchemaDescription) {
        self.init()
        
        entities = schema.entities.map(({ .init($0) }))
    }
}
