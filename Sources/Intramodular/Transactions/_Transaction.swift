//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

struct _TransactionID: Hashable {
    private let rawValue: AnyHashable
    
    init(rawValue: AnyHashable) {
        self.rawValue = rawValue
    }
}

/// An internal representation of a SwiftDB encapsulated database transaction.
protocol _Transaction: AnyObject, DatabaseCRUDQ, Identifiable where ID == _TransactionID {
    func commit() async throws
    
    func scope<T>(_ context: (_SwiftDB_RuntimeTaskContext) throws -> T) throws -> T
    
    func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T
}

/// A transaction wrapper that interposes another transaction.
///
/// This is needed to implement special transaction types (such as `_AutoCommittingTransaction`).
/// The runtime uses this to ensure that the interposed transaction is used over the base transacton.
protocol _TransactionInterposer: _Transaction {
    var interposedTransactionID: _TransactionID { get }
}

// MARK: - Implementation -

extension _Transaction {
    public func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T {
        try body()
    }
}

// MARK: - Supplementary API -

/// A link to a database transaction.
public final class _TransactionLink {
    public let transactionID: AnyHashable
    
    init(from transaction: any _Transaction) {
        self.transactionID = transaction.id
        
        /*asObjCObject(transaction).keepAlive(ExecuteClosureOnDeinit { [weak self] in
         if self != nil {
         assertionFailure("Transaction link has outlived transaction.")
         }
         })*/
    }
}
