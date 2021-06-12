//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swift
import CryptoKit

extension NSManagedObjectModel {
    @usableFromInline
    convenience init(_ schema: DatabaseSchema) throws {
        self.init()
        
        var relationshipNameToRelationship: [String: NSRelationshipDescription] = [:]
        var parentNameToChildrenMap: [String: [_SwiftDB_NSEntityDescription]] = [:]
        var nameToEntityMap: [String: _SwiftDB_NSEntityDescription] = [:]
        
        for entity in schema.entities {
            let description = try _SwiftDB_NSEntityDescription(entity)
            
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
            if let children = parentNameToChildrenMap[name] {
                entity.subentities = children.map {
                    $0.then {
                        $0.parent = entity
                    }
                }
            }
        }
        
        for entity in nameToEntityMap.values {
            for property in entity.properties {
                if let property = property as? NSRelationshipDescription {
                    if let destinationEntityName = property.destinationEntityName {
                        property.destinationEntity = nameToEntityMap[destinationEntityName]!
                    } else if let _SwiftDB_propertyDescription = entity._SwiftDB_allPropertyDescriptions[property.name] as? DatabaseSchema.Entity.Relationship {
                        property.destinationEntity = nameToEntityMap[_SwiftDB_propertyDescription.destinationEntityName]
                    } else {
                        assertionFailure()
                    }
                    
                    if let inverseRelationshipName = property.inverseRelationshipName {
                        property.inverseRelationship = relationshipNameToRelationship[inverseRelationshipName]
                    } else if let _SwiftDB_propertyDescription = entity._SwiftDB_allPropertyDescriptions[property.name] as? DatabaseSchema.Entity.Relationship {
                        property.inverseRelationship = _SwiftDB_propertyDescription.inverseRelationshipName.flatMap({ relationshipNameToRelationship[$0] })
                    }
                }
            }
        }
        
        self.entities = .init(nameToEntityMap.values.lazy.map({ $0 as NSEntityDescription }))
    }
}

extension NSPersistentStoreCoordinator {
    private static let _SwiftDB_databaseSchema_objcAssociationKey = ObjCAssociationKey<DatabaseSchema>()
    
    var _SwiftDB_databaseSchema: DatabaseSchema? {
        get {
            self[Self._SwiftDB_databaseSchema_objcAssociationKey]
        } set {
            self[Self._SwiftDB_databaseSchema_objcAssociationKey] = newValue
        }
    }
}
