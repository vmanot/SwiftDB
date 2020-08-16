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
        
        var relationshipNameToRelationship: [String: NSRelationshipDescription] = [:]
        var parentNameToChildrenMap: [String: [NSEntityDescription]] = [:]
        var nameToEntityMap: [String: NSEntityDescription] = [:]
        
        for entity in schema.entities {
            let description = NSEntityDescription(entity)
            
            nameToEntityMap[entity.name] = description
            
            if let parent = entity.parent {
                parentNameToChildrenMap[parent.name, default: []].insert(description)
            }
            
            for property in description.properties {
                if let property = property as? NSRelationshipDescription {
                    relationshipNameToRelationship[property.name] = property
                }
            }
        }
        
        for (name, entity) in nameToEntityMap {
            for property in entity.properties {
                if let property = property as? NSRelationshipDescription {
                    property.destinationEntity = nameToEntityMap[property.destinationEntityName!]!
                    property.inverseRelationship = property.inverseRelationshipName.flatMap({ relationshipNameToRelationship[$0] })
                }
            }
            
            if let children = parentNameToChildrenMap[name] {
                entity.subentities = children
            }
        }
        
        self.entities = .init(nameToEntityMap.values)
    }
}
