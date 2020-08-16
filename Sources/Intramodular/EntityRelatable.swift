//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public protocol _opaque_EntityRelatable {
    static var entityCardinality: EntityCardinality { get }
}

public protocol EntityRelatable: _opaque_EntityRelatable {
    associatedtype RelatableEntityType: Entity
    
    static func decode(from _: NSManagedObject, forKey _: AnyStringKey) throws -> Self
    func encode(to _: NSManagedObject, forKey _: AnyStringKey) throws
}

// MARK: - Implementation -

extension Entity {
    public static var entityCardinality: EntityCardinality {
        .one
    }
    
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        try Self(base: try cast(base.value(forKey: key.stringValue), to: NSManagedObject.self).unwrap()).unwrap()
    }
    
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self.base, forKey: key.stringValue)
    }
}

extension RelatedModels {
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        let value = try base.value(forKey: key.stringValue).unwrap()
        
        return .init(base: try cast(try cast(value, to: NSSet.self), to: Set<NSManagedObject>.self))
    }
    
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self.base as NSSet, forKey: key.stringValue)
    }
}

extension Optional: _opaque_EntityRelatable where Wrapped: _opaque_EntityRelatable {
    public static var entityCardinality: EntityCardinality {
        Wrapped.entityCardinality
    }
}

extension Optional: EntityRelatable where Wrapped: EntityRelatable {
    public typealias RelatableEntityType = Wrapped.RelatableEntityType
    
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws {
        try self?.encode(to: base, forKey: key)
    }
    
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Optional<Wrapped> {
        if base.value(forKey: key.stringValue) != nil {
            return .some(try Wrapped.decode(from: base, forKey: key))
        } else {
            return .none
        }
    }
}
