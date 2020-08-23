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
    
    var _runtime_underlyingObject: NSManagedObject? { get }
    
    static func toEntityDescription() -> EntityDescription
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation -

extension _opaque_Entity where Self: Entity {
    public static var _opaque_ParentType: _opaque_Entity.Type? {
        return nil
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
    public var _runtime_underlyingObject: NSManagedObject? {
        let instance = AnyNominalOrTupleMirror(self)!
        
        for (_, value) in instance {
            if let value = value as? _opaque_PropertyAccessor {
                return value.underlyingObject
            }
        }
        
        return nil
    }
    
    @usableFromInline
    var _runtime_propertyAccessors: [_opaque_PropertyAccessor] {
        AnyNominalOrTupleMirror(self)!.children.compactMap { key, value in
            (value as? _opaque_PropertyAccessor)
        }
    }
    
    @usableFromInline
    mutating func _runtime_configurePropertyAccessors(underlyingObject: NSManagedObject? = nil) {
        var instance = AnyNominalOrTupleMirror(self)!
        
        var isParentSet: Bool = false
        
        for (key, value) in instance.allChildren {
            if var property = value as? _opaque_PropertyAccessor {
                property.underlyingObject = underlyingObject
                
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                if self is _opaque_Subentity {
                    if let parentType = Self._opaque_ParentType, !isParentSet {
                        property._opaque_modelEnvironment.parent = parentType.init(_runtime_underlyingObject: underlyingObject)
                        
                        isParentSet = true
                    }
                }
                
                property._runtime_initialize()
                
                instance[key] = property
            }
        }
        
        self = instance.value as! Self
    }
    
    @usableFromInline
    init?(_runtime_underlyingObject object: NSManagedObject?) {
        if let object = object, let schema = object._SwiftDB_schemaDescription {
            guard let entityType = schema.entityNameToTypeMap[object.entity.name]?.value else {
                return nil
            }
            
            self = entityType.init() as! Self
        } else {
            self.init()
        }
        
        _runtime_configurePropertyAccessors(underlyingObject: object)
    }
}

extension _opaque_Entity where Self: AnyObject & Entity {
    public static var _opaque_ParentType: _opaque_Entity.Type? {
        ObjCClass(Self.self).superclass?.value as? _opaque_Entity.Type
    }
}

// MARK: -
extension NSEntityDescription {
    fileprivate func hasParentEntityOfName(_ name: String) -> Bool {
        if name == self.name {
            return true
        } else if let superentity = superentity {
            return superentity.hasParentEntityOfName(name)
        } else {
            return false
        }
    }
}
