//
// Copyright (c) Vatsal Manot
//

import Swallow

private struct _SwiftDB_TaskLocalValues {
    @TaskLocal static var transactionContext: _SwiftDB_TaskContext?
}

func _withSwiftDBTaskContext<T>(
    _ context: _SwiftDB_TaskContext? = nil,
    perform operation: (_SwiftDB_TaskContext) throws -> T
) throws -> T {
    if let context = context {
        if let existingContext = _SwiftDB_TaskLocalValues.transactionContext, let transactionInterposer = existingContext._taskRuntime as? any _SwiftDB_TaskRuntimeInterposer {
            if transactionInterposer.interposee == (try context._taskRuntime.unwrap()).id {
                let newContext = _SwiftDB_TaskContext(
                    databaseContext: existingContext.databaseContext,
                    _taskRuntime: transactionInterposer
                )
                
                return try _SwiftDB_TaskLocalValues.$transactionContext.withValue(newContext) {
                    try operation(newContext)
                }
            } else {
                fatalError() // FIXME
            }
        } else {
            return try _SwiftDB_TaskLocalValues.$transactionContext.withValue(context) {
                try operation(context)
            }
        }
    } else {
        return try operation(try _SwiftDB_TaskLocalValues.transactionContext.unwrap())
    }
}
