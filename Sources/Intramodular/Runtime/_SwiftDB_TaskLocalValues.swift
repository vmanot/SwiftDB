//
// Copyright (c) Vatsal Manot
//

import Swallow

private struct _SwiftDB_TaskLocalValues {
    @TaskLocal static var transactionContext: _SwiftDB_RuntimeTaskContext?
}

func _withRuntimeTaskContext<T>(
    _ context: _SwiftDB_RuntimeTaskContext? = nil,
    perform operation: (_SwiftDB_RuntimeTaskContext) throws -> T
) throws -> T {
    if let context = context {
        if let existingContext = _SwiftDB_TaskLocalValues.transactionContext, let transactionInterposer = existingContext.transaction as? any _TransactionInterposer {
            if transactionInterposer.interposedTransactionID == (try context.transaction.unwrap()).id {
                let newContext = _SwiftDB_RuntimeTaskContext(
                    databaseContext: existingContext.databaseContext,
                    transaction: transactionInterposer
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

func _with_Transaction<T>(
    _ transaction: any _Transaction,
    perform operation: (_SwiftDB_RuntimeTaskContext) throws -> T
) throws -> T {
    try _withRuntimeTaskContext { context in
        let newTransactionContext = _SwiftDB_RuntimeTaskContext(
            databaseContext: context.databaseContext,
            transaction: transaction
        )
        
        return try _withRuntimeTaskContext(newTransactionContext, perform: operation)
    }
}
