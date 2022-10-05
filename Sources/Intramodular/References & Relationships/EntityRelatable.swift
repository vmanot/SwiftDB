//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow
import Swift

/// A type that can be related to & from an entity.
public protocol EntityRelatable {
    associatedtype RelatableEntityType: Entity
    
    /// The cardinality of the number of models this type exports.
    static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality { get }

    init(noRelatedModels: ())

    /// Creates a new instance by decoding from the given database reference.
    static func decode(from _: AnyDatabaseRecord, forKey _: CodingKey) throws -> Self
    
    /// Encodes a relationship to this instance's related models into the given database reference.
    func encode(to _: AnyDatabaseRecord, forKey _: CodingKey) throws
    
    /// Exports all the models associated with this instance.
    func exportRelatableModels() throws -> [RelatableEntityType]
}

// MARK: - Implementation -

extension EntityRelatable where Self: Entity {
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .one
    }
    
    public init(noRelatedModels: Void) {
        try! self.init(from: nil) // FIXME!!!
    }
    
    public static func decode(from base: AnyDatabaseRecord, forKey key: CodingKey) throws -> Self {
        fatalError()
    }
    
    public func encode(to base: AnyDatabaseRecord, forKey key: CodingKey) throws {
        fatalError()
    }
    
    public func exportRelatableModels() throws -> [Self.RelatableEntityType] {
        return [try cast(self)]
    }
}

extension Optional: EntityRelatable where Wrapped: EntityRelatable {
    public typealias RelatableEntityType = Wrapped.RelatableEntityType
    
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        Wrapped.entityCardinality
    }

    public init(noRelatedModels: Void) {
        self = .some(Wrapped(noRelatedModels: ()))
    }

    public static func decode(
        from base: AnyDatabaseRecord,
        forKey key: CodingKey
    ) throws -> Optional<Wrapped> {
        if base.containsValue(forKey: key) {
            return try base.decode(Wrapped.self, forKey: key)
        } else {
            return nil
        }
    }
    
    public func encode(to base: AnyDatabaseRecord, forKey key: CodingKey) throws {
        fatalError()
    }
    
    public func exportRelatableModels() throws -> [RelatableEntityType] {
        if let wrapped = self {
            return try wrapped.exportRelatableModels()
        } else {
            return []
        }
    }
}
