//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct DatabaseTransactionContext {
    private enum Error: Swift.Error {
        case crossTransactionOperationDetected
    }
    
    let databaseContext: AnyDatabase.Context
    let transaction: any DatabaseTransaction
    
    public func validate(_ link: _DatabaseTransactionLink) throws {
        guard link.transactionID == transaction.id else {
            throw Error.crossTransactionOperationDetected
        }
    }
}

extension DatabaseTransactionContext {
    public func _recordContainer(
        for record: AnyDatabaseRecord
    ) throws -> _DatabaseRecordContainer {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)
        
        return .init(transactionContext: self, recordSchema: recordSchema, record: record)
    }
    
    public func createInstance<Instance: Entity>(
        _ instance: Instance.Type,
        for record: AnyDatabaseRecord
    ) throws -> Instance {
        try Instance(from: _recordContainer(for: record))
    }
}
