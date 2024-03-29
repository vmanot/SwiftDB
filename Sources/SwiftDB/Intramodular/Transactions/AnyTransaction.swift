//
// Copyright (c) Vatsal Manot
//

import Swallow
import SwiftAPI

public struct AnyTransaction {
    private let _SwiftDB_taskContext: _SwiftDB_TaskContext
    private let transaction: AnyDatabaseTransaction

    init(
        transaction: AnyDatabaseTransaction,
        _SwiftDB_taskContext: _SwiftDB_TaskContext
    ) {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
        self.transaction = transaction
    }

    private func scope<T>(_ operation: (_SwiftDB_TaskContext) throws -> T) throws -> T {
        try _withSwiftDBTaskContext(_SwiftDB_taskContext) { context in
            try operation(context)
        }
    }
}

extension AnyTransaction {
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        return try scope { context in
            let entity = try context.databaseContext.schema.entity(forModelType: entityType).unwrap()

            let record = try transaction.createRecord(
                withConfiguration: .init(
                    recordType: context.databaseContext.schemaAdaptor.recordType(for: entity.id),
                    recordID: nil,
                    zone: nil
                )
            )

            return try _SwiftDB_taskContext.createTransactionScopedInstance(
                entityType,
                for: record,
                transaction: transaction
            )
        }
    }

    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try scope { context in
            try transaction.delete(instance._databaseRecordProxy.recordID)
        }
    }
}
