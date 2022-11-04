//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Runtime
import Swallow

extension _CoreData {
    @objc(_SwiftDB_NSEntityDescription)
    class _SwiftDB_NSEntityDescription: NSEntityDescription, NSSecureCoding {
        weak var parent: _SwiftDB_NSEntityDescription?
        
        var _SwiftDB_propertyDescriptions: [String: _Schema.Entity.Property] = [:]
        
        @objc(supportsSecureCoding)
        static var supportsSecureCoding: Bool {
            true
        }
        
        var _SwiftDB_allPropertyDescriptions: [String: _Schema.Entity.Property] {
            guard let parent = parent else {
                return _SwiftDB_propertyDescriptions
            }
            
            return parent._SwiftDB_allPropertyDescriptions.merging(_SwiftDB_propertyDescriptions, uniquingKeysWith: { x, _ in x })
        }
        
        public convenience init(
            from entity: _Schema.Entity,
            in schema: _Schema
        ) throws {
            self.init()
            
            name = entity.name
            managedObjectClassName = try schema.generateNSManagedObjectClass(for: entity.id).name
            properties = try entity.properties.map({ try $0.toNSPropertyDescription() })
            
            for property in entity.properties {
                _SwiftDB_propertyDescriptions[property.name] = property
            }
            
            subentities = try entity.subentities.map {
                let subentity = try _SwiftDB_NSEntityDescription(from: $0, in: schema)
                
                subentity.parent = self
                
                return subentity
            }
        }
    }
}

// MARK: - Auxiliary Implementaton -

extension _Schema {
    fileprivate func generateNSManagedObjectClass(
        for entityID: _Schema.Entity.ID
    ) throws -> ObjCClass {
        let entity = try self[entityID].unwrap()
        
        let superclass = try entity.parent.map({ try generateNSManagedObjectClass(for: $0) }) ?? ObjCClass(_CoreData._SwiftDB_NSManagedObject.self)
        
        return ObjCClass(
            name: "_SwiftDB_" + entity.name,
            superclass: superclass
        )
    }
}

extension _Schema.Entity.Property {
    fileprivate func toNSPropertyDescription() throws -> NSPropertyDescription {
        switch self {
            case let attribute as _Schema.Entity.Attribute:
                return try NSAttributeDescription(attribute)
            case let relationship as _Schema.Entity.Relationship:
                return try NSRelationshipDescription(relationship)
            default:
                throw EmptyError()
        }
    }
}
