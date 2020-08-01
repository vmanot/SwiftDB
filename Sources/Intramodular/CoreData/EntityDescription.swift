//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swallow

public struct EntityDescription: AnyProtocol {
    public private(set) var name: String
    public private(set) var managedObjectClassName: String
    public private(set) var subentities: [EntityDescription]
    public private(set) var properties: [EntityPropertyDescription]
    
    public init(
        name: String,
        managedObjectClassName: String,
        subentities: [EntityDescription],
        properties: [EntityPropertyDescription]
    ) {
        self.name = name
        self.managedObjectClassName = managedObjectClassName
        self.subentities = subentities
        self.properties = properties
    }
    
    public mutating func insertSubentities(_ entities: [EntityDescription]) {
        subentities.insert(contentsOf: entities)
    }
}

// MARK: - Auxiliary Implementation -

extension NSEntityDescription {
    public convenience init(_ description: EntityDescription) {
        self.init()
        
        name = description.name
        managedObjectClassName = description.managedObjectClassName
        properties = description.properties.map({ $0.toNSPropertyDescription() })
        subentities = description.subentities.map({ .init($0) })
    }
}
