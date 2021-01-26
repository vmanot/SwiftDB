//
// Copyright (c) Vatsal Manot
//

import CoreData
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
            name: "_SwiftDB_NSManagedObject_" + name,
            superclass: nil
                ?? _opaque_ParentEntity?.underlyingDatabaseRecordClass
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
    mutating func _runtime_configurePropertyAccessors<Context: DatabaseRecordContext>(
        underlyingRecord: _opaque_DatabaseRecord?,
        context: Context.RecordCreateContext
    ) {
        var instance = AnyNominalOrTupleMirror(self)!
        
        var isParentSet: Bool = false
        
        for (key, value) in instance.allChildren {
            if var property = value as? _opaque_PropertyAccessor {
                property.underlyingRecord = underlyingRecord
                
                if property.name == nil {
                    property.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                }
                
                if self is _opaque_Subentity {
                    if let parentType = Self._opaque_ParentEntity, !isParentSet {
                        property._opaque_modelEnvironment.parent = parentType.init(_underlyingDatabaseRecord: underlyingRecord, context: context)
                        
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
    init<Context: DatabaseRecordContext>(
        _underlyingDatabaseRecord record: _opaque_DatabaseRecord?,
        context: Context.RecordCreateContext
    ) {
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
        
        _runtime_configurePropertyAccessors(underlyingRecord: record, context: context)
        
        if let record = record {
            record
                ._opaque_objectWillChange
                .publish(to: self)
                .store(in: record.cancellables)
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
    
    public var _opaque_objectWillChange: AnyPublisher<Any, Never> {
        _underlyingDatabaseRecord?._opaque_objectWillChange ?? Combine.Empty<Any, Never>().eraseToAnyPublisher()
    }
    
    public func _opaque_objectWillChange_send() throws {
        
    }
    
    public var _underlyingDatabaseRecord: _opaque_DatabaseRecord? {
        for (_, value) in AnyNominalOrTupleMirror(self)!.allChildren {
            if let value = value as? _opaque_PropertyAccessor {
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
