//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: Initiable {
    static var _opaque_ParentEntity: (any Entity.Type)? { get }
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation

extension _opaque_Entity  {
    var _runtime_propertyAccessors: [any _EntityPropertyAccessor] {
        AnyNominalOrTupleMirror(self)!.allChildren.compactMap { key, value in
            (value as? any _EntityPropertyAccessor)
        }
    }
    
    mutating func _runtime_configurePropertyAccessors(
        withRecordProxy recordProxy: _DatabaseRecordProxy?
    ) throws {
        var instance = AnyNominalOrTupleMirror(self)!
        
        for (key, value) in instance.allChildren {
            if let property = value as? any _EntityPropertyAccessor {
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                if let recordProxy = recordProxy {
                    try property.initialize(with: recordProxy)
                }
                
                instance[key] = property
            }
        }
        
        self = try cast(instance.subject, to: Self.self)
    }
    
    init(_databaseRecordProxy: _DatabaseRecordProxy?) throws {
        self.init()
        
        try _runtime_configurePropertyAccessors(withRecordProxy: _databaseRecordProxy)
    }
}

extension _opaque_Entity where Self: Entity {
    public static var _opaque_ParentEntity: (any Entity.Type)? {
        return nil
    }
        
    var _databaseRecordProxy: _DatabaseRecordProxy {
        get throws {
            for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
                if let value = value as? any _EntityPropertyAccessor {
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
}

extension _opaque_Entity where Self: Entity & Identifiable {
    public var _opaque_id: AnyHashable? {
        AnyHashable(id)
    }
}

// MARK: - Auxiliary

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
