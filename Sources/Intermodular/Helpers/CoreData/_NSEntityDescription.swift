//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swift

@objc(SwiftDB_NSEntityDescription)
class _NSEntityDescription: NSEntityDescription, NSSecureCoding {
    weak var parent: _NSEntityDescription?
    
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
    
    public convenience init(_ description: DatabaseSchema.Entity) {
        self.init()
        
        name = description.name
        managedObjectClassName = description.className
        properties = description.properties.map({ $0.toNSPropertyDescription() })
        
        for property in description.properties {
            _SwiftDB_propertyDescriptions[property.name] = property
        }
        
        subentities = description.subentities.knownValue?.map({ _NSEntityDescription($0) }) ?? []
    }
}
