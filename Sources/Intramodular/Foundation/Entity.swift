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
        guard let container = _underlyingDatabaseRecordContainer else {
            assertionFailure()
            
            return NilPredicateExpressionValue(nilLiteral: ())
        }
        
        return try! container.record._cast(to: _CoreData.DatabaseRecord.self).rawObject
    }
}
