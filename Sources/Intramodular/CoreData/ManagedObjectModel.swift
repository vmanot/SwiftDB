//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swallow

public struct ManagedObjectModel {
    public let entities: [EntityDescription]
    
    public init(_ entity: () -> EntityDescription) {
        self.entities = [entity()]
    }
    
    public init(@ArrayBuilder<EntityDescription> entities: () -> [EntityDescription]) {
        self.entities = entities()
    }
}

extension NSManagedObjectModel {
    public convenience init(_ model: ManagedObjectModel) {
        self.init()
        
        entities = model.entities.map({ .init($0) })
    }
}
