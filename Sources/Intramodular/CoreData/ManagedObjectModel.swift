//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swallow
import Swift

public struct ManagedObjectModel {
    public let entities: [EntityDescription]
    
    public init(entities: [EntityDescription]) {
        self.entities = entities
    }
}

extension NSManagedObjectModel {
    public convenience init(_ schema: ManagedObjectModel) {
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
    }
}
