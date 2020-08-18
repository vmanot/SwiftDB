//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public protocol _opaque_EntityRelatable {
    @inlinable
    static var entityCardinality: EntityCardinality { get }
    
    @inlinable
    init()
}

public protocol EntityRelatable: _opaque_EntityRelatable {
    associatedtype RelatableEntityType: Entity
    
    @inlinable
    static func decode(from _: NSManagedObject, forKey _: AnyStringKey) throws -> Self
    
    @inlinable
    func encode(to _: NSManagedObject, forKey _: AnyStringKey) throws
}

// MARK: - Implementation -

extension Entity {
    @inlinable
    public static var entityCardinality: EntityCardinality {
        .one
    }
    
    @inlinable
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        try Self(base: try cast(base.value(forKey: key.stringValue), to: NSManagedObject.self).unwrap()).unwrap()
    }
    
    @inlinable
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self.base, forKey: key.stringValue)
    }
}

extension Optional: _opaque_EntityRelatable where Wrapped: _opaque_EntityRelatable {
    @inlinable
    public static var entityCardinality: EntityCardinality {
        Wrapped.entityCardinality
    }
    
    @inlinable
    public init() {
        self = .some(.init())
    }
}

extension Optional: EntityRelatable where Wrapped: EntityRelatable {
    public typealias RelatableEntityType = Wrapped.RelatableEntityType
    
    @inlinable
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws {
        try self?.encode(to: base, forKey: key)
    }
    
    @inlinable
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Optional<Wrapped> {
        if base.value(forKey: key.stringValue) != nil {
            return .some(try Wrapped.decode(from: base, forKey: key))
        } else {
            return .none
        }
    }
}
