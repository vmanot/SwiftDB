//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

extension AnyDatabaseAccess {
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try recordContext.delete(AnyDatabaseRecord(from: instance))
    }
    
    public func delete<Instances: Sequence>(allOf instances: Instances) throws where Instances.Element: Entity {
        for instance in instances {
            try delete(instance)
        }
    }
}
