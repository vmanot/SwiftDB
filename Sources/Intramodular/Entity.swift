//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

/// An entity in a data schema.
public protocol Entity: _opaque_Entity, EntityRelatable, Model {
    associatedtype RelatableEntityType = Self
    
    typealias Relationship<Value: EntityRelatable, ValueEntity: Entity, InverseValue: EntityRelatable, InverseValueEntity: Entity> = EntityRelationship<Self, Value, ValueEntity, InverseValue, InverseValueEntity>
    
    static var name: String { get }
}

// MARK: - Implementation -



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
