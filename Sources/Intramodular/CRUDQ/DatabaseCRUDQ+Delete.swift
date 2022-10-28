//
// Copyright (c) Vatsal Manot
//

import Swallow

extension DatabaseCRUDQ {
    public func delete<Instances: Sequence>(allOf instances: Instances) throws where Instances.Element: Entity {
        for instance in instances {
            try delete(instance)
        }
    }
}
