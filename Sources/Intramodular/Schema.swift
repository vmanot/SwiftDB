//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

public protocol Schema {
    typealias Entities = [opaque_Entity.Type]
    
    @ArrayBuilder<opaque_Entity.Type>
    var entities: Entities { get }
}

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
