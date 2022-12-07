//
// Copyright (c) Vatsal Manot
//

import Swallow

final class _AnyDatabaseTaskRuntime: _SwiftDB_TaskRuntime {
    let id = _SwiftDB_TaskRuntimeID()

    private let base: AnyDatabaseTransaction
    private let databaseContext: AnyDatabase.Context

    init(
        base: AnyDatabaseTransaction,
        databaseContext: AnyDatabase.Context
    ) {
        self.base = base
        self.databaseContext = databaseContext
    }

    func commit() async throws {

    }

    func scope<T>(_ operation: (_SwiftDB_TaskContext) throws -> T) throws -> T {
        try _withSwiftDBTaskContext(.init(databaseContext: databaseContext, _taskRuntime: self)) { context in
            try operation(context)
        }
    }
}
