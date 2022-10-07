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

extension EntityPropertyAccessorModifier  {
    public var _runtimeMetadata: _opaque_EntityPropertyAccessorRuntimeMetadata {
        get {
            base._runtimeMetadata
        } set {
            base._runtimeMetadata = newValue
        }
    }
    
    public var _underlyingRecordContainer: _DatabaseRecordContainer? {
        get {
            base._underlyingRecordContainer
        } set {
            base._underlyingRecordContainer = newValue
        }
    }
    
    public var name: String? {
        get {
            base.name
        } set {
            base.name = newValue
        }
    }
        
    public func schema() throws -> _Schema.Entity.Property {
        try base.schema()
    }
    
    public func initialize(with container: _DatabaseRecordContainer) throws {
        try base.initialize(with: container)
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

/*// MARK: - Conformances -

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
*/
