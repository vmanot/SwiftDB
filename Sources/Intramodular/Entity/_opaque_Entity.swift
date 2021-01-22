//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Runtime
import Swallow

/// A shadow protocol for `Entity`.
public protocol _opaque_Entity: _opaque_EntityRelatable, Initiable, _opaque_ObservableObject {
    static var _opaque_Parent: _opaque_Entity.Type? { get }
    static var _opaque_ID: Any.Type? { get }
    
    var _opaque_id: AnyHashable? { get }
    
    var _runtime_underlyingDatabaseRecord: DatabaseRecord? { get }
    
    static var name: String { get }
    
    static func toEntityDescription() -> DatabaseSchema.Entity
}

extension _opaque_Entity where Self: Entity {
    public typealias RelatableEntityType = Self
}

// MARK: - Implementation -

extension _opaque_Entity {
    public static var underlyingDatabaseRecordClassName: String {
        "_SwiftDB_NSManagedObject_" + name
    }
    
    public static var underlyingDatabaseRecordClass: ObjCClass {
        ObjCClass(
            name: underlyingDatabaseRecordClassName,
            superclass: nil
                ?? _opaque_Parent?.underlyingDatabaseRecordClass
                ?? ObjCClass(NSXManagedObject.self)
        )
    }
    
    @usableFromInline
    var _runtime_propertyAccessors: [_opaque_PropertyAccessor] {
        AnyNominalOrTupleMirror(self)!.allChildren.compactMap { key, value in
            (value as? _opaque_PropertyAccessor)
        }
    }
    
    @usableFromInline
    mutating func _runtime_configurePropertyAccessors(underlyingRecord: DatabaseRecord?) {
        var instance = AnyNominalOrTupleMirror(self)!
        
        var isParentSet: Bool = false
        
        for (key, value) in instance.allChildren {
            if var property = value as? _opaque_PropertyAccessor {
                property.underlyingRecord = underlyingRecord
                
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                if self is _opaque_Subentity {
                    if let parentType = Self._opaque_Parent, !isParentSet {
                        property._opaque_modelEnvironment.parent = parentType.init(_runtime_underlyingDatabaseRecord: underlyingRecord)
                        
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
    init(_runtime_underlyingDatabaseRecord record: DatabaseRecord?) {
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
        
        _runtime_configurePropertyAccessors(underlyingRecord: record)
        
        if let record = record {
            record
                ._opaque_objectWillChange
                .publish(to: self)
                .store(in: record.cancellables)
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
    
    public var _opaque_objectWillChange: AnyPublisher<Any, Never> {
        _runtime_underlyingDatabaseRecord?._opaque_objectWillChange ?? Combine.Empty<Any, Never>().eraseToAnyPublisher()
    }
    
    public func _opaque_objectWillChange_send() throws {
        try _runtime_underlyingDatabaseRecord.unwrap()._opaque_objectWillChange_send()
    }
    
    public var _runtime_underlyingDatabaseRecord: DatabaseRecord? {
        for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
            if let value = value as? _opaque_PropertyAccessor {
                return value.underlyingRecord
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
