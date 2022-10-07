//
// Copyright (c) Vatsal Manot
//

import Swallow

private struct _SwiftDB_TaskLocalValues {
    @TaskLocal static var transactionContext: DatabaseTransactionContext?
}

func withDatabaseTransactionContext<T>(
    _ context: DatabaseTransactionContext? = nil,
    perform operation: (DatabaseTransactionContext) throws -> T
) throws -> T {
    if let context = context {
        if let existingContext = _SwiftDB_TaskLocalValues.transactionContext, existingContext.transaction.id == context.transaction.id {
            return try _SwiftDB_TaskLocalValues.$transactionContext.withValue(existingContext) {
                try operation(existingContext)
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

func withDatabaseTransaction<T>(
    _ transaction: any DatabaseTransaction,
    perform operation: (DatabaseTransactionContext) throws -> T
) throws -> T {
    try withDatabaseTransactionContext { context in
        let newTransactionContext = DatabaseTransactionContext(
            databaseContext: context.databaseContext,
            transaction: transaction
        )
        
        return try withDatabaseTransactionContext(newTransactionContext, perform: operation)
    }
}
