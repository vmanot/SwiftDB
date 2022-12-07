//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: Initiable {
    static var _opaque_ParentEntity: (any Entity.Type)? { get }
    
    var _databaseRecordProxy: _DatabaseRecordProxy { get throws }
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
        withRecordProxy recordProxy: _DatabaseRecordProxy?
    ) throws {
        var instance = AnyNominalOrTupleMirror(self)!
        
        for (key, value) in instance.allChildren {
            if let property = value as? any EntityPropertyAccessor {
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                if let recordProxy = recordProxy {
                    try property.initialize(with: recordProxy)
                }
                
                instance[key] = property
            }
        }
        
        self = try cast(instance.value, to: Self.self)
    }
    
    init(_databaseRecordProxy: _DatabaseRecordProxy?) throws {
        self.init()
        
        if let databaseRecordProxy = _databaseRecordProxy, type(of: self) is AnyObject.Type {
            try _runtime_configurePropertyAccessors(withRecordProxy: databaseRecordProxy)
        } else {
            try _runtime_configurePropertyAccessors(withRecordProxy: nil)
        }
    }
}

extension _opaque_Entity where Self: Entity {
    public static var _opaque_ParentEntity: (any Entity.Type)? {
        return nil
    }
    
    public var _opaque_id: AnyHashable? {
        nil
    }

    public func _opaque_objectWillChange_send() throws {
        
    }
    
    public var _databaseRecordProxy: _DatabaseRecordProxy {
        get throws {
            for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
                if let value = value as? any EntityPropertyAccessor {
                    if let proxy = value._underlyingRecordProxy {
                        return proxy
                    }
                }
            }
            
            throw _opaque_EntityError.failedToResolveDatabaseRecordProxy
        }
    }
}

extension _opaque_Entity where Self: Entity & AnyObject {
    public static var _opaque_ParentEntity: (any Entity.Type)? {
        ObjCClass(Self.self).superclass?.value as? any Entity.Type
    }
}

extension _opaque_Entity where Self: Entity & ObservableObject {
    public static var _opaque_ParentEntity: (any Entity.Type)? {
        ObjCClass(Self.self).superclass?.value as? any Entity.Type
    }
    
    public func _opaque_objectWillChange_send() throws {
        try cast(objectWillChange, to: _opaque_VoidSender.self).send()
    }
}

extension _opaque_Entity where Self: Entity & Identifiable {
    public var _opaque_id: AnyHashable? {
        AnyHashable(id)
    }
}

// MARK: - Auxiliary -

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

fileprivate enum _opaque_EntityError: _SwiftDB_Error {
    case failedToResolveDatabaseRecordProxy
}
