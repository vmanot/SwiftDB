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
    static var entityCardinality: DatabaseSchema.Entity.Relationship.EntityCardinality { get }
    
    @inlinable
    init(noRelatedModels: ())
}

/// A type that can be related to & from an entity.
public protocol EntityRelatable: _opaque_EntityRelatable {
    associatedtype RelatableEntityType: Entity
    
    /// The cardinality of the number of models this type exports.
    @inlinable
    static var entityCardinality: DatabaseSchema.Entity.Relationship.EntityCardinality { get }

    /// Creates a new instance by decoding from the given database reference.
    @inlinable
    static func decode(from _: _opaque_DatabaseRecord, forKey _: AnyStringKey) throws -> Self
    
    /// Encodes a relationship to this instance's related models into the given database reference.
    @inlinable
    func encode(to _: _opaque_DatabaseRecord, forKey _: AnyStringKey) throws
    
    /// Exports all the models associated with this instance.
    @inlinable
    func exportRelatableModels() throws -> [RelatableEntityType]
}

// MARK: - Implementation -

extension EntityRelatable where Self: Entity {
    public static var entityCardinality: DatabaseSchema.Entity.Relationship.EntityCardinality {
        .one
    }
    
    public init(noRelatedModels: Void) {
        try! self.init(_underlyingDatabaseRecord: nil)
    }
    
    public static func decode(from base: _opaque_DatabaseRecord, forKey key: AnyStringKey) throws -> Self {
        fatalError()
    }
    
    public func encode(to base: _opaque_DatabaseRecord, forKey key: AnyStringKey) throws {
        fatalError()
    }
    
    public func exportRelatableModels() throws -> [Self.RelatableEntityType] {
        return [try cast(self)]
    }
}

extension Optional: _opaque_EntityRelatable where Wrapped: _opaque_EntityRelatable {
    @inlinable
    public static var entityCardinality: DatabaseSchema.Entity.Relationship.EntityCardinality {
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
    public static func decode(from base: _opaque_DatabaseRecord, forKey key: AnyStringKey) throws -> Optional<Wrapped> {
        fatalError()
    }
    
    @inlinable
    public func encode(to base: _opaque_DatabaseRecord, forKey key: AnyStringKey) throws {
        fatalError()
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
