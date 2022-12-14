//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct AnyDatabaseTransactionExecutor: DatabaseTransactionExecutor {
    public typealias Database = AnyDatabase
    public typealias Transaction = AnyDatabaseTransaction
    
    private let base: any DatabaseTransactionExecutor
    
    public init<Executor: DatabaseTransactionExecutor>(erasing base: Executor) {
        self.base = base
    }
    
    public func execute<R>(
        _ body: @escaping (Transaction) throws -> R
    ) async throws -> R {
        try await base.execute({ try body(AnyDatabaseTransaction(erasing: $0)) })
    }
    
    public func execute<R>(
        queryRequest: Database.ZoneQueryRequest,
        _ body: @escaping (Database.ZoneQueryRequest.Result) throws -> R
    ) async throws -> R {
        try await base._opaque_execute(queryRequest: queryRequest, body)
    }
    
    public func executeSynchronously<R>(
        _ body: @escaping (Transaction) throws -> R
    ) throws -> R {
        try base.executeSynchronously({ try body(AnyDatabaseTransaction(erasing: $0)) })
    }
}

// MARK: - Auxiliary -

extension DatabaseTransactionExecutor {
    fileprivate func _opaque_execute<R>(
        queryRequest: AnyDatabase.ZoneQueryRequest,
        _ body: @escaping (AnyDatabase.ZoneQueryRequest.Result) throws -> R
    ) async throws -> R {
        try await execute(queryRequest: queryRequest._cast(to: Database.ZoneQueryRequest.self)) {
            try body(AnyDatabase.ZoneQueryRequest.Result(_erasing: $0))
        }
    }
}
