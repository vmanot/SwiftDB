//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Runtime
import Swallow

/// An entity in a data schema.
public protocol Entity: _opaque_Entity, EntityRelatable, Model, PredicateExpressionPrimitiveConvertible {
    associatedtype RelatableEntityType = Self
    
    typealias Relationship<Value: EntityRelatable, ValueEntity: Entity & Identifiable, InverseValue: EntityRelatable, InverseValueEntity: Entity & Identifiable> = EntityRelationship<Self, Value, ValueEntity, InverseValue, InverseValueEntity> where Self: Identifiable
    
    static var name: String { get }
}

// MARK: - Implementation -

extension Entity {
    public static var name: String {
        String(describing: Self.self)
    }
}

extension Entity {
    public func toPredicateExpressionPrimitive() -> PredicateExpressionPrimitive {
        (_underlyingDatabaseRecord as! _CoreData.DatabaseRecord).base
    }
}
