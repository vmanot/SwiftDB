//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
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
    
    public convenience init(_ description: DatabaseSchema.Entity) throws {
        self.init()
        
        name = description.name
        managedObjectClassName = description.className
        properties = try description.properties.map({ try NSPropertyDescription(from: $0) })
        
        for property in description.properties {
            _SwiftDB_propertyDescriptions[property.name] = property
        }
        
        subentities = try description.subentities.knownValue?.map {
            let subentity = try _SwiftDB_NSEntityDescription($0)
            
            subentity.parent = self
            
            return subentity
        } ?? []
    }
}

