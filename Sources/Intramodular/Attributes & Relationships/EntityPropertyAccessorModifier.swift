//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol EntityPropertyAccessorModifier: EntityPropertyAccessor {
    associatedtype EntityPropertyAccessorType: EntityPropertyAccessor
        
    var base: EntityPropertyAccessorType { get }
}

// MARK: - Implementation -

extension EntityPropertyAccessorModifier {
    public var _opaque_objectWillChange: AnyObjectWillChangePublisher {
        base._opaque_objectWillChange
    }
    
    public var objectWillChange: EntityPropertyAccessorType.ObjectWillChangePublisher {
        base.objectWillChange
    }
    
    public func _opaque_objectWillChange_send() throws {
        try base._opaque_objectWillChange_send()
    }
}

extension EntityPropertyAccessorModifier where EntityPropertyAccessorType: _opaque_EntityPropertyAccessor {
    var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration {
        get {
            base.propertyConfiguration
        } set {
            base.propertyConfiguration = newValue
        }
    }
    
    var underlyingRecord: _opaque_DatabaseRecord? {
        get {
            base.underlyingRecord
        } set {
            base.underlyingRecord = newValue
        }
    }
    
    var name: String? {
        get {
            base.name
        } set {
            base.name = newValue
        }
    }
        
    func schema() throws -> DatabaseSchema.Entity.Property {
        try base.schema()
    }
    
    func _runtime_initializePostNameResolution() throws {
        try base._runtime_initializePostNameResolution()
    }
}

extension EntityPropertyAccessorModifier {
    public func decode(from decoder: Decoder) throws {
        try base.decode(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try base.encode(to: encoder)
    }
}

// MARK: - Conformances -

@propertyWrapper
public final class RenamingIdentifier<EntityPropertyAccessorType: EntityPropertyAccessor, WrappedValue>: EntityPropertyAccessorModifier {
    public var base: EntityPropertyAccessorType
    public let wrappedValue: WrappedValue
    
    public init<T>(
        wrappedValue: EntityPropertyAccessorType,
        _ identifier: String
    ) where EntityPropertyAccessorType == Attribute<T>,
            WrappedValue == EntityPropertyAccessorType
    {
        self.base = wrappedValue
        self.wrappedValue = wrappedValue
        
        base.propertyConfiguration.renamingIdentifier = identifier
    }
        
    public init<T>(
        wrappedValue: WrappedValue,
        _ identifier: String
    ) where WrappedValue: EntityPropertyAccessorModifier,
            WrappedValue.EntityPropertyAccessorType == Attribute<T>,
            WrappedValue.EntityPropertyAccessorType == EntityPropertyAccessorType
    {
        self.base = wrappedValue.base
        self.wrappedValue = wrappedValue
        
        base.propertyConfiguration.renamingIdentifier = identifier
    }
}

extension RenamingIdentifier: _opaque_EntityPropertyAccessor where EntityPropertyAccessorType: _opaque_EntityPropertyAccessor {
    
}
