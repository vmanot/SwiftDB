//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public protocol DatabaseTransaction: AnyObject, DatabaseCRUDQ, Identifiable {
    func commit() async throws
    
    func scope<T>(_ context: (DatabaseTransactionContext) throws -> T) throws -> T
    
    func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T
}

// MARK: - Implementation -

extension DatabaseTransaction {
    public func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T {
        try body()
    }
}

// MARK: - Supplementary API -

/// A link to a database transaction.
public final class _DatabaseTransactionLink {
    public let transactionID: AnyHashable
    
    init(from transaction: any DatabaseTransaction) {
        self.transactionID = transaction.id
        
        asObjCObject(transaction).keepAlive(ExecuteClosureOnDeinit { [weak self] in
            if self != nil {
                assertionFailure("Transaction link has outlived transaction.")
            }
        })
    }
}
