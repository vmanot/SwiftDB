//
// Copyright (c) Vatsal Manot
//

import Swallow
import SwiftAPI

public struct AnyLocalTransaction: LocalDatabaseCRUDQ {
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

extension AnyLocalTransaction {
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        try scope { context in
            try AnyTransaction(transaction: transaction, _SwiftDB_taskContext: context).create(entityType)
        }
    }

    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) throws -> QueryRequest<Model>.Output {
        return try scope { context in
            let results = try transaction.executeSynchronously(
                DatabaseZoneQueryRequest(
                    from: request,
                    databaseContext: _SwiftDB_taskContext.databaseContext
                )
            )

            return QueryRequest<Model>.Output(
                results: try results.records?.map {
                    try context.createTransactionScopedInstance(
                        Model.self,
                        for: $0,
                        transaction: transaction
                    )
                } ?? []
            )
        }
    }

    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try scope { context in
            try AnyTransaction(transaction: transaction, _SwiftDB_taskContext: context).delete(instance)
        }
    }
}
