//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swift
import CryptoKit

extension NSManagedObjectModel {
    @usableFromInline
    convenience init(_ schema: _Schema) throws {
        self.init()
        
        var relationshipNameToRelationship: [String: NSRelationshipDescription] = [:]
        var parentNameToChildrenMap: [String: [_CoreData._SwiftDB_NSEntityDescription]] = [:]
        var nameToEntityMap: [String: _CoreData._SwiftDB_NSEntityDescription] = [:]
        
        for entity in schema.entities {
            let description = try _CoreData._SwiftDB_NSEntityDescription(from: entity, in: schema)
            
            nameToEntityMap[entity.name] = description
            
            if let parentID = entity.parent, let parent = schema[parentID] {
                parentNameToChildrenMap[parent.name, default: []].insert(description)
            }
            
            for property in description.properties {
                if let property = property as? NSRelationshipDescription {
                    relationshipNameToRelationship[property.name] = property
                }
            }
        }
        
        for (name, entity) in nameToEntityMap {
            if let children = parentNameToChildrenMap[name] {
                entity.subentities = children.map {
                    $0.withMutableScope {
                        $0.parent = entity
                    }
                }
            }
        }
        
        for entity in nameToEntityMap.values {
            for property in entity.properties {
                if let property = property as? NSRelationshipDescription {
                    if let _SwiftDB_propertyDescription = entity._SwiftDB_allPropertyDescriptions[property.name] as? _Schema.Entity.Relationship {
                        
                        let destinationEntityID = try _SwiftDB_propertyDescription.relationshipConfiguration.destinationEntity.unwrap()
                        let destinationEntity = try schema[destinationEntityID].unwrap()
                        
                        property.destinationEntity = nameToEntityMap[destinationEntity.name]
                    } else {
                        assertionFailure()
                    }
                    
                    if let _SwiftDB_propertyDescription = entity._SwiftDB_allPropertyDescriptions[property.name] as? _Schema.Entity.Relationship {
                        property.inverseRelationship = _SwiftDB_propertyDescription.relationshipConfiguration.inverseRelationshipName.flatMap({ relationshipNameToRelationship[$0] })
                    } else {
                        assertionFailure()
                    }
                }
            }
        }
        
        self.entities = .init(nameToEntityMap.values.lazy.map({ $0 as NSEntityDescription }))
    }
}
