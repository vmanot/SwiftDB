//
// Copyright (c) Vatsal Manot
//

import API
import Diagnostics
import Merge
import Swallow

/// A type that wraps a record space into a SwiftDB transaction.
final class _AnyDatabaseRecordSpaceTaskRuntime: _SwiftDB_TaskRuntime {
    let id = _SwiftDB_TaskRuntimeID()
    
    private let databaseContext: AnyDatabase.Context
    private let recordSpace: AnyDatabase.RecordSpace
    
    init(
        databaseContext: AnyDatabase.Context,
        recordSpace: AnyDatabase.RecordSpace
    ) {
        self.databaseContext = databaseContext
        self.recordSpace = recordSpace
    }
    
    func scope<T>(_ operation: (_SwiftDB_TaskContext) throws -> T) throws -> T {
        try _withSwiftDBTaskContext(.init(databaseContext: databaseContext, _taskRuntime: self)) { context in
            try operation(context)
        }
    }
}

extension _AnyDatabaseRecordSpaceTaskRuntime {
    func willChangePublisher() -> AnyObjectWillChangePublisher {
        recordSpace.objectWillChange
    }
}
