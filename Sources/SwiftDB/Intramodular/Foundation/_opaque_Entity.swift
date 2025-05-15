//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: Initiable {
    /// 对应的父实体类型（如果有的话）。
    static var _opaque_ParentEntity: (any Entity.Type)? { get }
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation

extension _opaque_Entity  {
    // 获取所有属性访问器。
    var _runtime_propertyAccessors: [any _EntityPropertyAccessor] {
        InstanceMirror(self)!.allChildren.compactMap { key, value in
            (value as? any _EntityPropertyAccessor)
        }
    }
    
    // 配置属性访问器。
    // 该方法会遍历所有属性访问器，并为每个访问器设置名称和记录代理。
    mutating func _runtime_configurePropertyAccessors(
        withRecordProxy recordProxy: _DatabaseRecordProxy?
    ) throws {
        var instance = InstanceMirror(self)!
        
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
            for (_, value) in InstanceMirror(self)!.allChildren {
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
    /// 检查当前实体是否是另一个实体的父类。
    public static func isSuperclass(of other: _opaque_Entity.Type) -> Bool {
        if other == Self.self {
            return false
        } else if other is Self.Type { // 检查 other 是否可以被转换为 Self.Type
            return true
        } else {
            return false
        }
    }
}

fileprivate enum _opaque_EntityError: _SwiftDB_Error {
    case failedToResolveDatabaseRecordProxy
}
