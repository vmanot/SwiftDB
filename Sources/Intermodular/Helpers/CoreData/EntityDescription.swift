//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swallow

public struct EntityDescription: Codable, Hashable {
    @Indirect
    public var parent: EntityDescription?
    public let name: String
    public let managedObjectClassName: String
    public let subentities: MaybeKnown<[EntityDescription]>
    public let properties: [EntityPropertyDescription]
    
    public init(
        parent: EntityDescription?,
        name: String,
        managedObjectClassName: String,
        subentities: MaybeKnown<[EntityDescription]>,
        properties: [EntityPropertyDescription]
    ) {
        self.parent = parent
        self.name = name
        self.managedObjectClassName = managedObjectClassName
        self.subentities = subentities
        self.properties = properties
    }
}

// MARK: - Auxiliary Implementation -

class _NSEntityDescription: NSEntityDescription {
    weak var parent: _NSEntityDescription?
    
    var _SwiftDB_propertyDescriptions: [String: EntityPropertyDescription] = [:]
    
    var _SwiftDB_allPropertyDescriptions: [String: EntityPropertyDescription] {
        guard let parent = parent else {
            return _SwiftDB_propertyDescriptions
        }
        
        return parent._SwiftDB_propertyDescriptions.merging(_SwiftDB_propertyDescriptions, uniquingKeysWith: { x, _ in x })
    }
    
    public convenience init(_ description: EntityDescription) {
        self.init()
        
        name = description.name
        managedObjectClassName = description.managedObjectClassName
        properties = description.properties.map({ $0.toNSPropertyDescription() })
        
        for property in description.properties {
            _SwiftDB_propertyDescriptions[property.name] = property
        }
        
        subentities = description.subentities.knownValue?.map({ _NSEntityDescription($0) }) ?? []
    }
}
