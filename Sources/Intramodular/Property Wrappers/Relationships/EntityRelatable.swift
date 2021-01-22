//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow
import Swift

/// A type-erased shadow protocol for `EntityRelatable`.
public protocol _opaque_EntityRelatable {
    @inlinable
    static var entityCardinality: EntityCardinality { get }
    
    @inlinable
    init(noRelatedModels: ())
}

/// A type that can be related to/fro an entity.
public protocol EntityRelatable: _opaque_EntityRelatable {
    associatedtype RelatableEntityType: Entity
    
    /// The cardinality of the number of models this type exports.
    @inlinable
    static var entityCardinality: EntityCardinality { get }
    
    /// Creates a new instance by decoding from the given database reference.
    @inlinable
    static func decode(from _: NSManagedObject, forKey _: AnyStringKey) throws -> Self
    
    /// Encodes a relationship to this instance's related models into the given database reference.
    @inlinable
    func encode(to _: NSManagedObject, forKey _: AnyStringKey) throws
    
    /// Exports all the models associated with this instance.
    @inlinable
    func exportRelatableModels() throws -> [RelatableEntityType]
}

// MARK: - Implementation -

extension EntityRelatable where Self: Entity {
    public static var entityCardinality: EntityCardinality {
        .one
    }
    
    public init(noRelatedModels: Void) {
        self.init(_runtime_underlyingDatabaseRecord: nil)
    }
    
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        Self(_runtime_underlyingDatabaseRecord: _CoreData.DatabaseRecord(base: try cast(base.value(forKey: key.stringValue), to: NSManagedObject.self).unwrap()))
    }
    
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self._runtime_underlyingDatabaseRecord, forKey: key.stringValue)
    }
    
    public func exportRelatableModels() throws -> [Self.RelatableEntityType] {
        return [try cast(self)]
    }
}

extension Optional: _opaque_EntityRelatable where Wrapped: _opaque_EntityRelatable {
    @inlinable
    public static var entityCardinality: EntityCardinality {
        Wrapped.entityCardinality
    }
    
    @inlinable
    public init(noRelatedModels: Void) {
        self = .some(.init(noRelatedModels: ()))
    }
}

extension Optional: EntityRelatable where Wrapped: EntityRelatable {
    public typealias RelatableEntityType = Wrapped.RelatableEntityType
    
    @inlinable
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Optional<Wrapped> {
        if base.value(forKey: key.stringValue) != nil {
            return .some(try Wrapped.decode(from: base, forKey: key))
        } else {
            return .none
        }
    }
    
    @inlinable
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws {
        try self?.encode(to: base, forKey: key)
    }
    
    @inlinable
    public func exportRelatableModels() throws -> [RelatableEntityType] {
        if let wrapped = self {
            return try wrapped.exportRelatableModels()
        } else {
            return []
        }
    }
}
