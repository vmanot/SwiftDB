//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

extension AnyDatabaseContainer {
    public final class LiveAccess: @unchecked Sendable {
        private let taskQueue = TaskQueue()
        
        private var base: AnyDatabase?
        
        public var isInitialized: Bool {
            base != nil
        }
        
        private var baseUnwrapped: AnyDatabase {
            get throws {
                try base.unwrap()
            }
        }
        
        public init() {
            
        }
        
        func setBase(_ base: AnyDatabase?) {
            self.base = base
        }
    }
}

extension AnyDatabaseContainer.LiveAccess {
    public func transact<R: Sendable>(
        _ body: @escaping @Sendable (AnyLocalTransaction) throws -> R
    ) async throws -> R {
        try await baseUnwrapped.transact(body)
    }
    
    public func querySubscription<Model>(
        for request: QueryRequest<Model>
    ) throws -> QuerySubscription<Model> {
        try baseUnwrapped.querySubscription(for: request)
    }
    
    public func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try baseUnwrapped.queryExecutionTask(for: request)
        } catch {
            return .just(.failure(error))
        }
    }
}

extension AnyDatabaseContainer.LiveAccess: DatabaseCRUDQ {
    public func create<Instance: Entity>(_ entityType: Instance.Type) async throws -> Instance {
        try await transact { transaction in
            try transaction.create(entityType) // FIXME: !!!: Convert to snapshot
        }
    }
    
    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) async throws -> QueryRequest<Model>.Output {
        try await queryExecutionTask(for: request).value
    }
    
    public func delete<Instance: Entity>(_ instance: Instance) async throws {
        try await transact { transaction in
            try transaction.delete(instance)
        }
    }
    
    public func deleteAll() async throws {
        try await transact { transaction in
            let all = try transaction.fetchAll()
            
            try all.forEach({ try transaction.delete($0) })
        }
    }
}

// MARK: - Auxiliary

extension AnyDatabase {
    public func transact<R>(
        _ body: @escaping (AnyTransaction) throws -> R
    ) async throws -> R {
        let executor = try transactionExecutor()
        
        return try await executor.execute { transaction in
            try body(
                AnyTransaction(
                    transaction: transaction,
                    _SwiftDB_taskContext: _SwiftDB_TaskContext.defaultContext(for: self)
                )
            )
        }
    }
    
    @_disfavoredOverload
    public func transact<R>(
        _ body: @escaping (AnyLocalTransaction) throws -> R
    ) async throws -> R {
        let executor = try transactionExecutor()
        
        return try await executor.execute { transaction in
            try body(
                AnyLocalTransaction(
                    transaction: transaction,
                    _SwiftDB_taskContext: _SwiftDB_TaskContext.defaultContext(for: self)
                )
            )
        }
    }
    
    public func transactSynchronously<R>(
        _ body: @escaping (AnyLocalTransaction) throws -> R
    ) throws -> R {
        let executor = try transactionExecutor()
        
        return try executor.executeSynchronously { transaction in
            try body(
                AnyLocalTransaction(
                    transaction: .init(erasing: transaction),
                    _SwiftDB_taskContext: _SwiftDB_TaskContext.defaultContext(for: self)
                )
            )
        }
    }
    
    public func transact<Model, R>(
        with request: QueryRequest<Model>,
        _ body: @escaping @Sendable (QueryRequest<Model>.Output) throws -> R
    ) async throws -> R {
        let database = AnyDatabase(erasing: self)
        let executor = try database.transactionExecutor()
        let _SwiftDB_taskContext = _SwiftDB_TaskContext.defaultContext(for: database)
        
        let queryRequest = try AnyDatabase.ZoneQueryRequest(
            from: request,
            databaseContext: database.context
        )
        
        return try await executor.execute(queryRequest: queryRequest) { result in
            let queryResult = QueryRequest.Output(
                results: try (result.records ?? []).map { record in
                    try _withSwiftDBTaskContext(_SwiftDB_taskContext) { context in
                        try context.createSnapshotInstance(
                            Model.self,
                            for: record
                        )
                    }
                }
            )
            
            return try body(queryResult)
        }
    }
    
    func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        PassthroughTask<QueryRequest<Model>.Output, Error> { attemptToFulfill -> Void in
            let attemptToFulfill = _UncheckedSendable(attemptToFulfill)
            
            Task {
                do {
                    try await self.transact(with: request) { result in
                        attemptToFulfill.wrappedValue(.success(result))
                    }
                } catch {
                    attemptToFulfill.wrappedValue(.failure(error))
                }
            }
        }
        .eraseToAnyTask()
    }
    
    public func querySubscription<Model>(
        for request: QueryRequest<Model>
    ) throws -> SwiftDB.QuerySubscription<Model> {
        let database = AnyDatabase(erasing: self)
        
        return SwiftDB.QuerySubscription<Model>(
            from: try database.querySubscription(
                for: try AnyDatabase.ZoneQueryRequest(
                    from: request,
                    databaseContext: database.context
                )
            ),
            context: .defaultContext(for: self)
        )
    }
}
