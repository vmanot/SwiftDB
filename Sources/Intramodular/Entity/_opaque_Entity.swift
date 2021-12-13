//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: _opaque_EntityRelatable, _opaque_ObservableObject, Initiable {
    static var _opaque_ParentEntity: _opaque_Entity.Type? { get }
    static var _opaque_ID: Any.Type? { get }
    
    var _opaque_id: AnyHashable? { get }
    
    var _underlyingDatabaseRecord: _opaque_DatabaseRecord? { get }
    
    static var name: String { get }
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation -

extension _opaque_Entity {
    static var underlyingDatabaseRecordClass: ObjCClass {
        ObjCClass(
            name: "_SwiftDB_" + name,
            superclass: nil
            ?? _opaque_ParentEntity?.underlyingDatabaseRecordClass
            ?? ObjCClass(NSXManagedObject.self)
        )
    }
    
    var _runtime_propertyAccessors: [_opaque_EntityPropertyAccessor] {
        AnyNominalOrTupleMirror(self)!.allChildren.compactMap { key, value in
            (value as? _opaque_EntityPropertyAccessor)
        }
    }
    
    mutating func _runtime_configurePropertyAccessors(underlyingRecord: _opaque_DatabaseRecord?) throws {
        var instance = AnyNominalOrTupleMirror(self)!
        
        for (key, value) in instance.allChildren {
            if let property = value as? _opaque_EntityPropertyAccessor {
                property.underlyingRecord = underlyingRecord
                
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                try property._runtime_initializePostNameResolution()
                
                instance[key] = property
            }
        }
        
        self = try cast(instance.value, to: Self.self)
    }
    
    init(_underlyingDatabaseRecord record: _opaque_DatabaseRecord?) throws {
        if let record = record, let schema = (record as! _CoreData.DatabaseRecord).base._SwiftDB_databaseSchema {
            if let entityType = schema.entityNameToTypeMap[(record as! _CoreData.DatabaseRecord).base.entity.name]?.value {
                self = entityType.init() as! Self
            } else {
                assertionFailure()
                
                self.init()
            }
        } else {
            self.init()
        }
        
        try _runtime_configurePropertyAccessors(underlyingRecord: record)
        
        if let record = record, type(of: self) is AnyObject.Type {
            record
                ._opaque_objectWillChange
                .publish(to: self)
                .subscribe(in: record.cancellables)
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
        _underlyingDatabaseRecord?._opaque_objectWillChange ?? .empty
    }
    
    public func _opaque_objectWillChange_send() throws {
        
    }
    
    public var _underlyingDatabaseRecord: _opaque_DatabaseRecord? {
        for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
            if let value = value as? _opaque_EntityPropertyAccessor {
                return value.underlyingRecord
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
