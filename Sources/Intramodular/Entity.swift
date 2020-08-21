//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: _opaque_EntityRelatable, Initiable {
    static var _opaque_ParentType: _opaque_Entity.Type? { get }
    
    static var name: String { get }
    static var managedObjectClassName: String { get }
    static var managedObjectClass: ObjCClass { get }
    
    static func toEntityDescription() -> EntityDescription
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

/// An entity in a data schema.
@dynamicMemberLookup
public protocol Entity: _opaque_Entity, EntityRelatable, Model {
    associatedtype RelatableEntityType = Self
    associatedtype Parent: Entity = _DefaultParentEntity
    
    typealias Relationship<Value: EntityRelatable, ValueEntity: Entity, InverseValue: EntityRelatable, InverseValueEntity: Entity> = EntityRelationship<Self, Value, ValueEntity, InverseValue, InverseValueEntity>
    
    static var name: String { get }
    
    subscript<Value>(dynamicMember _: ReferenceWritableKeyPath<Parent, Value>) -> Value { get set }
}

// MARK: - Implementation -

extension _opaque_Entity where Self: Entity {
    public static var _opaque_ParentType: _opaque_Entity.Type? {
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
            superclass: _opaque_ParentType?.managedObjectClass ?? ObjCClass(NSXManagedObject.self)
        )
    }
    
    public static func toEntityDescription() -> EntityDescription {
        .init(self)
    }
}

extension _opaque_Entity {
    @usableFromInline
    var base: NSManagedObject? {
        let instance = AnyNominalOrTupleValue(self)!
        
        for (_, value) in instance {
            if let value = value as? _opaque_PropertyAccessor {
                return value.base
            }
        }
        
        return nil
    }
    
    @usableFromInline
    var _runtime_propertyAccessors: [_opaque_PropertyAccessor] {
        AnyNominalOrTupleValue(self)!.compactMap { key, value in
            (value as? _opaque_PropertyAccessor)
        }
    }
    
    @usableFromInline
    mutating func _runtime_configurePropertyAccessors(base: NSManagedObject? = nil) {
        var emptyInstance = AnyNominalOrTupleValue(self)!
        
        var isParentSet: Bool = false
        
        for (key, value) in emptyInstance {
            if var attribute = value as? _opaque_PropertyAccessor {
                attribute.base = base
                attribute.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                
                emptyInstance[key] = attribute
                
                if let parentType = Self._opaque_ParentType, !isParentSet {
                    attribute._opaque_modelEnvironment.parent = parentType.init(base: base)
                    
                    isParentSet = true
                }
            }
        }
        
        self = emptyInstance.value as! Self
    }
    
    public init?(base: NSManagedObject?) {
        if let base = base {
            guard base.entity.name == Self.name else {
                return nil
            }
        }
        
        self.init()
        
        _runtime_configurePropertyAccessors(base: base)
    }
}

extension Entity {
    public static var name: String {
        String(describing: Self.self)
    }
}

// MARK: - Auxiliary Implementation -

extension EntityDescription {
    public init(_ type: _opaque_Entity.Type) {
        var instance = type.init()
        
        instance._runtime_configurePropertyAccessors()
        
        self.init(
            parent: type._opaque_ParentType?.toEntityDescription(),
            name: type.name,
            managedObjectClassName: type.managedObjectClass.name,
            subentities: .unknown,
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
