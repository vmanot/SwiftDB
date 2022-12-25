//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// An entity in a data schema.
public protocol Entity: _opaque_Entity, PredicateExpressionPrimitiveConvertible {
    typealias Relationship<Value: _EntityRelationshipDestination> = EntityRelationship<Value>
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
