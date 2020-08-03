//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

public struct SchemaDescription {
    public let entities: [EntityDescription]
    
    public init<S: Schema>(_ schema: S) {
        self.entities = schema.entities.map({ $0.toEntityDescription() })
    }
}

// MARK: - Auxiliary Implementation -

extension NSManagedObjectModel {
    public convenience init(_ schema: SchemaDescription) {
        self.init()
        
        var parentNameToChildrenMap: [String: [NSEntityDescription]] = [:]
        var nameToEntityMap: [String: NSEntityDescription] = [:]
        
        for entity in schema.entities {
            let description = NSEntityDescription(entity)
            
            nameToEntityMap[entity.name] = description
            
            if let parent = entity.parent {
                parentNameToChildrenMap[parent.name, default: []].insert(description)
            }
        }
        
        for name in nameToEntityMap.keys {
            if let children = parentNameToChildrenMap[name] {
                nameToEntityMap[name]?.subentities = children
            }
        }
        
        self.entities = .init(nameToEntityMap.values)
        
        entities = schema.entities.map(({ .init($0) }))
    }
}
