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

extension EntityPropertyAccessorModifier where EntityPropertyAccessorType: _EntityPropertyAccessor {
    var _runtimeMetadata: _EntityPropertyAccessorRuntimeMetadata {
        get {
            base._runtimeMetadata
        } set {
            base._runtimeMetadata = newValue
        }
    }
    
    var _underlyingRecordProxy: _DatabaseRecordProxy? {
        get {
            base._underlyingRecordProxy
        } set {
            base._underlyingRecordProxy = newValue
        }
    }
    
    var name: String? {
        get {
            base.name
        } set {
            base.name = newValue
        }
    }
        
    func schema() throws -> _Schema.Entity.Property {
        try base.schema()
    }
    
    func initialize(with container: _DatabaseRecordProxy) throws {
        try base.initialize(with: container)
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
