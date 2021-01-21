//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Runtime
import Swallow

/// An entity in a data schema.
public protocol Entity: _opaque_Entity, EntityRelatable, Model {
    associatedtype RelatableEntityType = Self
    
    typealias Relationship<Value: EntityRelatable, ValueEntity: Entity & Identifiable, InverseValue: EntityRelatable, InverseValueEntity: Entity & Identifiable> = EntityRelationship<Self, Value, ValueEntity, InverseValue, InverseValueEntity> where Self: Identifiable
    
    static var name: String { get }
}

// MARK: - Implementation -

extension Entity {
    public static var name: String {
        String(describing: Self.self)
    }
    
    public static var managedObjectClassName: String {
        "_SwiftDB_NSManagedObject_" + name
    }
    
    public static var managedObjectClass: ObjCClass {
        ObjCClass(
            name: managedObjectClassName,
            superclass: nil
                ?? _opaque_Parent?.managedObjectClass
                ?? ObjCClass(NSXManagedObject.self)
        )
    }
    
    public static func toEntityDescription() -> DatabaseSchema.Entity {
        .init(self)
    }
}

// MARK: - Auxiliary Implementation -

extension DatabaseSchema.Entity {
    public init(_ type: _opaque_Entity.Type) {
        var instance = type.init()
        
        instance._runtime_configurePropertyAccessors(underlyingRecord: nil)
        
        self.init(
            parent: type._opaque_Parent?.toEntityDescription(),
            name: type.name,
            managedObjectClassName: type.managedObjectClass.name,
            subentities: .unknown,
            properties: instance._runtime_propertyAccessors.map({ $0.schema() })
        )
    }
}

@usableFromInline
class _EntityToNSManagedObjectAdaptor<T: Entity>: NSXManagedObject {
    
}

public struct _DefaultParentEntity: Entity {
    public static var name: String {
        Never.materialize(reason: .abstract)
    }
    
    public static var version: Version? {
        Never.materialize(reason: .abstract)
    }
    
    public init() {
        self = Never.materialize(reason: .abstract)
    }
}
