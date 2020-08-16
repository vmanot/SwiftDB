//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swallow

public struct EntityDescription: Codable {
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

extension NSEntityDescription {
    public convenience init(_ description: EntityDescription) {
        self.init()
        
        name = description.name
        managedObjectClassName = description.managedObjectClassName
        properties = description.properties.map({ $0.toNSPropertyDescription() })
        subentities = description.subentities.knownValue?.map({ .init($0) }) ?? []
    }
}
