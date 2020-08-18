//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

public struct SchemaDescription {
    public let entities: [EntityDescription]
    
    @inlinable
    public init<S: Schema>(_ schema: S) {
        self.entities = schema.entities.map({ $0.toEntityDescription() })
    }
}

// MARK: - Auxiliary Implementation -

extension NSManagedObjectModel {
    @usableFromInline
    convenience init(_ schema: SchemaDescription) {
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
