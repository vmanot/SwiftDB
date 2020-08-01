//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol opaque_Entity: Initiable {
    static var opaque_ParentType: opaque_Entity.Type? { get }
    static var name: String { get }
    static var managedObjectClassName: String { get }
    static var managedObjectClass: ObjCClass { get }
    
    var _runtime_propertyAccessors: [opaque_PropertyAccessor] { get }
    
    mutating func _runtime_configurePropertyAccessors()
    
    static func toEntityDescription() -> EntityDescription
}

/// An entity in a data schema.
public protocol Entity: opaque_Entity, Model {
    associatedtype Parent: Entity = _DefaultParentEntity
    
    static var name: String { get }
}

// MARK: - Implementation -

extension opaque_Entity where Self: Entity {
    public static var opaque_ParentType: opaque_Entity.Type? {
        guard Parent.self != _DefaultParentEntity.self else {
            return nil
        }
        
        return Parent.self
    }
    
    public static var managedObjectClassName: String {
        "_SwiftDB_NSManagedObject_" + name
    }
    
    public static var managedObjectClass: ObjCClass {
        ObjCClass(
            name: managedObjectClassName,
            superclass: opaque_ParentType?.managedObjectClass ?? ObjCClass(NSXManagedObject.self)
        )
    }
    
    public var _runtime_propertyAccessors: [opaque_PropertyAccessor] {
        AnyNominalOrTupleValue(self)!.compactMap { key, value in
            (value as? opaque_PropertyAccessor)
        }
    }
    
    public mutating func _runtime_configurePropertyAccessors() {
        var emptyInstance = AnyNominalOrTupleValue(self)!
        
        for (key, value) in emptyInstance {
            if var attribute = value as? opaque_Attribute {
                attribute.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                
                emptyInstance[key] = attribute
            }
        }
        
        self = emptyInstance.value as! Self
    }
    
    public static func toEntityDescription() -> EntityDescription {
        .init(self)
    }
}

extension Entity {
    public static var name: String {
        String(describing: Self.self)
    }
}

// MARK: - Auxiliary Implementation -

extension EntityDescription {
    public init(_ type: opaque_Entity.Type) {
        var instance = type.init()
        
        instance._runtime_configurePropertyAccessors()
        
        self.init(
            name: type.name,
            managedObjectClassName: type.managedObjectClassName,
            subentities: [],
            properties: instance._runtime_propertyAccessors.map({ $0.toEntityPropertyDescription() })
        )
    }
}

@usableFromInline
class _EntityToNSManagedObjectAdaptor<T: Entity>: NSXManagedObject {
    
}

public struct _DefaultParentEntity: Entity {
    public static var name: String {
        TODO.unimplemented
    }
    
    public static var version: Version? {
        TODO.unimplemented
    }
    
    public init() {
        TODO.unimplemented
    }
}
