//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct _SwiftDB_RuntimeTaskContext {
    private enum Error: Swift.Error {
        case transactionMissing
        case crossTransactionOperationDetected
    }
    
    let databaseContext: AnyDatabase.Context
    let transaction: (any _Transaction)?
    
    public func validate(_ link: _TransactionLink) throws {
        guard let transaction = transaction else {
            throw Error.transactionMissing
        }
        
        guard link.transactionID == transaction.id else {
            throw Error.crossTransactionOperationDetected
        }
    }
}

extension _SwiftDB_RuntimeTaskContext {
    public func _recordContainer(
        for record: AnyDatabaseRecord
    ) throws -> _DatabaseRecordContainer {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)
        
        return try .init(transactionContext: self, recordSchema: recordSchema, record: record)
    }
    
    public func createInstance<Instance: Entity>(
        _ instance: Instance.Type,
        for record: AnyDatabaseRecord
    ) throws -> Instance {
        try Instance(from: _recordContainer(for: record))
    }
}
