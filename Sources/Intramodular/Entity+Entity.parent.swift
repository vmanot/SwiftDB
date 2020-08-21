//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

extension Entity where Parent == _DefaultParentEntity {
    public var parent: Parent {
        .init()
    }
}

extension Entity {
    public var parent: Parent {
        _runtime_propertyAccessors[0]._opaque_modelEnvironment.parent as! Parent
    }
}

extension Entity {
    public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Parent, Value>) -> Value {
        get {
            parent[keyPath: keyPath]
        } set {
            parent[keyPath: keyPath] = newValue
        }
    }
}
