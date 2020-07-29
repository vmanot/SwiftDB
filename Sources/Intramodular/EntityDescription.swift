//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

extension EntityDescription {
    public init(_ type: opaque_Entity.Type) {
        self.init(name: type.name, managedObjectClassName: type.managedObjectClassName)
        
        let emptyInstance = AnyNominalOrTupleValue(type.init())!
        
        for (key, value) in emptyInstance {
            if var attribute = value as? opaque_Attribute {
                attribute.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                
                properties.append(EntityAttributeDescription(attribute))
            }
        }
    }
}
