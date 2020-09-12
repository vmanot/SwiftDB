//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: _opaque_EntityRelatable, Initiable {
    static var _opaque_Parent: _opaque_Entity.Type? { get }
    static var _opaque_ID: Any.Type? { get }
    
    var _opaque_id: AnyHashable? { get }
    var _opaque_objectWillChange: _opaque_VoidSender? { get }
    
    var _runtime_underlyingObject: NSManagedObject? { get }
    
    static var name: String { get }
    static var managedObjectClassName: String { get }
    static var managedObjectClass: ObjCClass { get }
    
    static func toEntityDescription() -> EntityDescription
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation -

extension _opaque_Entity {
    @usableFromInline
    var _runtime_propertyAccessors: [_opaque_PropertyAccessor] {
        AnyNominalOrTupleMirror(self)!.allChildren.compactMap { key, value in
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
                    if let parentType = Self._opaque_Parent, !isParentSet {
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
    init(_runtime_underlyingObject object: NSManagedObject?) {
        if let object = object, let schema = object._SwiftDB_schemaDescription {
            if let entityType = schema.entityNameToTypeMap[object.entity.name]?.value {
                self = entityType.init() as! Self
            } else {
                assertionFailure()
                
                self.init()
            }
        } else {
            self.init()
        }
        
        _runtime_configurePropertyAccessors(underlyingObject: object)
        
        if let objectWillChange = _opaque_objectWillChange, let object = object as? NSXManagedObject {
            object
                .objectWillChange
                .publish(to: objectWillChange)
                .sink()
                .store(in: object.cancellables)
        }
    }
}

extension _opaque_Entity where Self: Entity {
    public static var _opaque_Parent: _opaque_Entity.Type? {
        return nil
    }
    
    public static var _opaque_ID: Any.Type? {
        nil
    }
    
    public var _opaque_id: AnyHashable? {
        nil
    }
    
    public var _opaque_objectWillChange: _opaque_VoidSender? {
        nil
    }
    
    public var _runtime_underlyingObject: NSManagedObject? {
        for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
            if let value = value as? _opaque_PropertyAccessor {
                return value.underlyingObject
            }
        }
        
        return nil
    }
}

extension _opaque_Entity where Self: Entity & AnyObject {
    public static var _opaque_Parent: _opaque_Entity.Type? {
        ObjCClass(Self.self).superclass?.value as? _opaque_Entity.Type
    }
}

extension _opaque_Entity where Self: Entity & Identifiable {
    public static var _opaque_ID: Any.Type? {
        ID.self
    }
    
    public var _opaque_id: AnyHashable? {
        AnyHashable(id)
    }
}

extension _opaque_Entity where Self: Entity & ObservableObject, Self.ObjectWillChangePublisher: _opaque_VoidSender {
    public var _opaque_objectWillChange: _opaque_VoidSender? {
        objectWillChange
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
