//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct RecordMetadata<T> {
    public let id: AnyDatabaseRecord.ID
}

@dynamicMemberLookup
public struct RecordSnapshot<T> {
    fileprivate let base: T

    public var recordMetadata: RecordMetadata<T> {
        let recordProxy = try! cast(base, to: (any Entity).self)._databaseRecordProxy

        return .init(
            id: recordProxy.recordID
        )
    }

    init(from model: T, context: _SwiftDB_TaskContext) {
        self.base = model
    }

    init(
        from record: AnyDatabaseRecord,
        context: _SwiftDB_TaskContext
    ) throws {
        self.base = try context.createSnapshotInstance(T.self, for: record)
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
