//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct RecordInstanceMetadata {
    public let recordID: AnyDatabaseRecord.ID
    
    public static func from(instance: Any) throws -> Self {
        if let instance = instance as? (any Entity) {
            return try .init(
                recordID: instance._databaseRecordProxy.recordID
            )
        } else {
            throw EmptyError()
        }
    }
}

@dynamicMemberLookup
public struct RecordSnapshot<T> {
    fileprivate let base: T
    
    let instanceMetadata: RecordInstanceMetadata
    
    init(from instance: T) throws {
        self.base = instance
        self.instanceMetadata = try .from(instance: instance)
    }
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<T, Value>) -> Value {
        base[keyPath: keyPath]
    }
}

extension RecordSnapshot where T: PredicateExpressionPrimitiveConvertible {
    public func toPredicateExpressionPrimitive() -> PredicateExpressionPrimitive {
        base.toPredicateExpressionPrimitive()
    }
}
