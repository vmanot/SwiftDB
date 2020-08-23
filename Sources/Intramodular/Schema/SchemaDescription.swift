//
// Copyright (c) Vatsal Manot
//

import Compute
import CoreData
import Runtime
import Swallow
import SwiftUI

/// A type-erased description of a `Schema`.
public struct SchemaDescription: Hashable {
    public let name: String
    
    @usableFromInline
    var entityNameToTypeMap = BidirectionalMap<String,  Metatype<_opaque_Entity.Type>>()
    @usableFromInline
    var entityDescriptionToTypeMap = BidirectionalMap<EntityDescription,  Metatype<_opaque_Entity.Type>>()
    
    public var entities: AnySequence<EntityDescription> {
        .init(entityDescriptionToTypeMap.keys)
    }
    
    @inlinable
    public init(_ schema: Schema) {
        self.name = schema.name
        
        for entityType in schema.entities {
            entityNameToTypeMap[entityType.name] = .init(entityType)
            entityDescriptionToTypeMap[entityType.toEntityDescription()] = .init(entityType)
        }
    }
}

// MARK: - Auxiliary Implementation -

extension NSManagedObjectModel {
    @usableFromInline
    convenience init(_ schema: SchemaDescription) {
        self.init()
        
        var relationshipNameToRelationship: [String: NSRelationshipDescription] = [:]
        var parentNameToChildrenMap: [String: [_NSEntityDescription]] = [:]
        var nameToEntityMap: [String: _NSEntityDescription] = [:]
        
        for entity in schema.entities {
            let description = _NSEntityDescription(entity)
            
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
                    } else if let _SwiftDB_propertyDescription = entity._SwiftDB_allPropertyDescriptions[property.name] as? EntityRelationshipDescription {
                        property.destinationEntity = nameToEntityMap[_SwiftDB_propertyDescription.destinationEntityName]
                    } else {
                        assertionFailure()
                    }
                    
                    if let inverseRelationshipName = property.inverseRelationshipName {
                        property.inverseRelationship = relationshipNameToRelationship[inverseRelationshipName]
                    } else if let _SwiftDB_propertyDescription = entity._SwiftDB_allPropertyDescriptions[property.name] as? EntityRelationshipDescription {
                        property.inverseRelationship = _SwiftDB_propertyDescription.inverseRelationshipName.flatMap({ relationshipNameToRelationship[$0] })
                    }
                }
            }
        }
        
        self.entities = .init(nameToEntityMap.values.lazy.map({ $0 as NSEntityDescription }))
    }
}

extension NSPersistentStoreCoordinator {
    private static let _SwiftDB_schemaDescription_objcAssociationKey = ObjCAssociationKey<SchemaDescription>()
    
    var _SwiftDB_schemaDescription: SchemaDescription? {
        get {
            self[Self._SwiftDB_schemaDescription_objcAssociationKey]
        } set {
            self[Self._SwiftDB_schemaDescription_objcAssociationKey] = newValue
        }
    }
}

extension NSManagedObject {
    var _SwiftDB_schemaDescription: SchemaDescription? {
        managedObjectContext?.persistentStoreCoordinator?._SwiftDB_schemaDescription
    }
}

extension EnvironmentValues {
    private struct _EnvironmentKey: EnvironmentKey {
        static let defaultValue: SchemaDescription? = nil
    }
    
    public var schemaDescription: SchemaDescription? {
        get {
            self[_EnvironmentKey]
        } set {
            self[_EnvironmentKey] = newValue
        }
    }
}
