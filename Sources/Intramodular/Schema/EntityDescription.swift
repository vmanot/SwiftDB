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
