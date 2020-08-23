//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public protocol _opaque_Subentity: _opaque_Entity {
    
}

extension _opaque_Entity where Self: Subentity {
    public static var _opaque_ParentType: _opaque_Entity.Type? {
        guard Parent.self != _DefaultParentEntity.self else {
            return nil
        }
        
        return Parent.self
    }
}

@dynamicMemberLookup
public protocol Subentity: _opaque_Subentity, Entity {
    associatedtype Parent: Entity = _DefaultParentEntity
    
    var parent: Parent { get }
    
    subscript<Value>(dynamicMember _: ReferenceWritableKeyPath<Parent, Value>) -> Value { get nonmutating set }
}

// MARK: - Implementation -

extension Subentity where Parent == _DefaultParentEntity {
    public var parent: Parent {
        .init()
    }
}

extension Subentity {
    public var parent: Parent {
        _runtime_propertyAccessors[0]._opaque_modelEnvironment.parent as! Parent
    }
}

extension Subentity {
    public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Parent, Value>) -> Value {
        get {
            parent[keyPath: keyPath]
        } nonmutating set {
            parent[keyPath: keyPath] = newValue
        }
    }
}
