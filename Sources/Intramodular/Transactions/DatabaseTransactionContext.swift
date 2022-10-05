//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct DatabaseTransactionContext {
    let databaseContext: AnyDatabase.Context
    let transaction: any DatabaseTransaction
    
    func scope<T>(_ body: () throws -> T) rethrows -> T {
        try _SwiftDB_TaskLocalValues.$transactionContext.withValue(self) {
            try body()
        }
    }
}

extension DatabaseTransactionContext {
    public func _recordContainer(
        for record: AnyDatabaseRecord
    ) throws -> _AnyDatabaseRecordContainer {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)

        return .init(transactionContext: self, recordSchema: recordSchema, record: record)
    }
}
