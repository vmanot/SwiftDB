//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// An entity in a data schema.
public protocol Entity: _opaque_Entity, EntityRelatable, PredicateExpressionPrimitiveConvertible {
    associatedtype RelatableEntityType = Self
    
    typealias Relationship<Value: EntityRelatable, ValueEntity: Entity & Identifiable, InverseValue: EntityRelatable, InverseValueEntity: Entity & Identifiable> = EntityRelationship<Self, Value, ValueEntity, InverseValue, InverseValueEntity> where Self: Identifiable
}

// MARK: - Implementation -

extension Entity {
    public func toPredicateExpressionPrimitive() -> PredicateExpressionPrimitive {
        do {
            return try _databaseRecordProxy.recordID._cast(to: PredicateExpressionPrimitiveConvertible.self).toPredicateExpressionPrimitive()
        } catch {
            assertionFailure(error)
            
            return NilPredicateExpressionValue(nilLiteral: ())
        }
    }
}
