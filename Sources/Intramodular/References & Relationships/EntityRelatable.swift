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
    static func decode(from _: _DatabaseRecordContainer, forKey _: CodingKey) throws -> Self
    
    /// Encodes a relationship to this instance's related models into the given database reference.
    func encode(to _: _DatabaseRecordContainer, forKey _: CodingKey) throws
}

// MARK: - Implementation -

extension EntityRelatable where Self: Entity {
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .one
    }
    
    public init(noRelatedModels: Void) {
        try! self.init(from: nil) // FIXME!!!
    }
    
    public static func decode(
        from container: _DatabaseRecordContainer,
        forKey key: CodingKey
    ) throws -> Self {
        try withDatabaseTransactionContext { context in
            try context.validate(container.transactionLink)
            
            let record = try container.relationship(for: key).toOneRelationship().getRecord().unwrap()
            
            return try context.createInstance(Self.self, for: record)
        }
    }
    
    public func encode(to container: _DatabaseRecordContainer, forKey key: CodingKey) throws {
        fatalError()
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
        from container: _DatabaseRecordContainer,
        forKey key: CodingKey
    ) throws -> Optional<Wrapped> {
        if container.containsValue(forKey: key) {
            return try container.decode(Wrapped.self, forKey: key)
        } else {
            return nil
        }
    }
    
    public func encode(to container: _DatabaseRecordContainer, forKey key: CodingKey) throws {
        fatalError()
    }
}
