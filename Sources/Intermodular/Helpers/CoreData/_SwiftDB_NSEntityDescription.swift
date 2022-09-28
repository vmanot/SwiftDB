//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Runtime
import Swallow

@objc(_SwiftDB_NSEntityDescription)
class _SwiftDB_NSEntityDescription: NSEntityDescription, NSSecureCoding {
    weak var parent: _SwiftDB_NSEntityDescription?
    
    var _SwiftDB_propertyDescriptions: [String: DatabaseSchema.Entity.Property] = [:]
    
    @objc(supportsSecureCoding)
    static var supportsSecureCoding: Bool {
        true
    }
    
    var _SwiftDB_allPropertyDescriptions: [String: DatabaseSchema.Entity.Property] {
        guard let parent = parent else {
            return _SwiftDB_propertyDescriptions
        }
        
        return parent._SwiftDB_allPropertyDescriptions.merging(_SwiftDB_propertyDescriptions, uniquingKeysWith: { x, _ in x })
    }
    
    public convenience init(
        from entity: DatabaseSchema.Entity,
        in schema: DatabaseSchema
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


fileprivate extension DatabaseSchema {
    func generateNSManagedObjectClass(
        for entityID: DatabaseSchema.Entity.ID
    ) throws -> ObjCClass {
        let entity = try self[entityID].unwrap()
        
        let superclass = try entity.parent.map({ try generateNSManagedObjectClass(for: $0) }) ?? ObjCClass(NSXManagedObject.self)
        
        return ObjCClass(
            name: "_SwiftDB_" + entity.name,
            superclass: superclass
        )
    }
}
