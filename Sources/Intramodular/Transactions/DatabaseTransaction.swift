//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol DatabaseTransaction: DatabaseCRUDQ {
    func commit() async throws
    
    func _scopeRecordMutation<T>(_ body: () throws -> T) rethrows -> T
    func _withTransactionContext<T>(_ context: (DatabaseTransactionContext) throws -> T) rethrows -> T
}

// MARK: - Implementation -

extension DatabaseTransaction {
    public func _scopeRecordMutation<T>(_ body: () throws -> T) rethrows -> T {
        try body()
    }
}
