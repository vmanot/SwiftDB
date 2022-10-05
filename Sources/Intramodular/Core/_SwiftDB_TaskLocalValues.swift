//
// Copyright (c) Vatsal Manot
//

import Swallow

struct _SwiftDB_TaskLocalValues {
    @TaskLocal static var transactionContext: DatabaseTransactionContext?
}
