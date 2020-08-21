//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

@dynamicMemberLookup
public protocol ChildEntity: Entity {
    associatedtype Parent: Entity = _DefaultParentEntity
    
    subscript<Value>(dynamicMember _: ReferenceWritableKeyPath<Parent, Value>) -> Value { get nonmutating set }
}

extension ChildEntity where Parent == _DefaultParentEntity {
    public var parent: Parent {
        .init()
    }
}

extension ChildEntity {
    public var parent: Parent {
        _runtime_propertyAccessors[0]._opaque_modelEnvironment.parent as! Parent
    }
}

extension ChildEntity {
    public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Parent, Value>) -> Value {
        get {
            parent[keyPath: keyPath]
        } nonmutating set {
            parent[keyPath: keyPath] = newValue
        }
    }
}
