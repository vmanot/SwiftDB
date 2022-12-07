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
}

// MARK: - Implementation -

extension EntityRelatable where Self: Entity {
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .one
    }
    
    public init(noRelatedModels: Void) {
        try! self.init(_databaseRecordProxy: nil) // FIXME!!!
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
}
