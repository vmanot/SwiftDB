//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: _opaque_ObservableObject, Initiable {
    static var _opaque_ParentEntity: _opaque_Entity.Type? { get }
    
    var _underlyingDatabaseRecordContainer: _AnyDatabaseRecordContainer? { get }
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation -

extension _opaque_Entity  {
    var _runtime_propertyAccessors: [any EntityPropertyAccessor] {
        AnyNominalOrTupleMirror(self)!.allChildren.compactMap { key, value in
            (value as? any EntityPropertyAccessor)
        }
    }
    
    mutating func _runtime_configurePropertyAccessors(
        recordContainer: _AnyDatabaseRecordContainer?
    ) throws {
        var instance = AnyNominalOrTupleMirror(self)!
        
        for (key, value) in instance.allChildren {
            if let property = value as? any EntityPropertyAccessor {
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                if let recordContainer = recordContainer {
                    try property.initialize(with: recordContainer)
                }
                
                instance[key] = property
            }
        }
        
        self = try cast(instance.value, to: Self.self)
    }
    
    init(from recordContainer: _AnyDatabaseRecordContainer?) throws {
        self.init()
        
        try _runtime_configurePropertyAccessors(recordContainer: recordContainer)
        
        if let recordContainer = recordContainer, type(of: self) is AnyObject.Type {
            recordContainer
                .objectWillChange
                .publish(to: self)
                .subscribe(in: recordContainer.record.cancellables)
        }
    }
}

extension _opaque_Entity where Self: Entity {
    public static var _opaque_ParentEntity: _opaque_Entity.Type? {
        return nil
    }
    
    public static var _opaque_ID: Any.Type? {
        nil
    }
    
    public var _opaque_id: AnyHashable? {
        nil
    }
    
    public var _opaque_objectWillChange: AnyObjectWillChangePublisher {
        _underlyingDatabaseRecordContainer?.objectWillChange ?? .empty
    }
    
    public func _opaque_objectWillChange_send() throws {
        
    }
    
    public var _underlyingDatabaseRecordContainer: _AnyDatabaseRecordContainer? {
        for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
            if let value = value as? any EntityPropertyAccessor {
                return value._underlyingRecordContainer
            }
        }
        
        return nil
    }
}

extension _opaque_Entity where Self: Entity & AnyObject {
    public static var _opaque_ParentEntity: _opaque_Entity.Type? {
        ObjCClass(Self.self).superclass?.value as? _opaque_Entity.Type
    }
}


extension _opaque_Entity where Self: Entity & ObservableObject {
    public static var _opaque_ParentEntity: _opaque_Entity.Type? {
        ObjCClass(Self.self).superclass?.value as? _opaque_Entity.Type
    }
    
    public func _opaque_objectWillChange_send() throws {
        try cast(objectWillChange, to: _opaque_VoidSender.self).send()
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

// MARK: - Helpers -

extension _opaque_Entity {
    public static func isSuperclass(of other: _opaque_Entity.Type) -> Bool {
        if other == Self.self {
            return false
        } else if other is Self.Type {
            return true
        } else {
            return false
        }
    }
}
