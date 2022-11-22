//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

extension AnyDatabaseContainer {
    public final class LiveAccess: ObservableObject {
        private let taskQueue = TaskQueue()
        
        @Published private var base: AnyDatabase?
        
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

extension AnyDatabaseContainer.LiveAccess: LocalDatabaseCRUDQ {
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        try baseUnwrapped.transactSynchronously { transaction in
            try transaction.create(entityType) // FIXME!!!: Convert to snapshot
        }
    }
    
    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) throws -> QueryRequest<Model>.Output {
        try baseUnwrapped.transactSynchronously { transaction in
            try transaction.execute(request) // FIXME!!!: Convert to snapshot
        }
    }
    
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try baseUnwrapped.transactSynchronously { transaction in
            try transaction.delete(instance) // FIXME!!!: Convert to snapshot
        }
    }
}

extension AnyDatabaseContainer.LiveAccess {
    public func querySubscription<Model>(
        for request: QueryRequest<Model>
    ) throws -> QuerySubscription<Model> {
        try baseUnwrapped.querySubscription(for: request)
    }
    
    func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try baseUnwrapped.queryExecutionTask(for: request)
        } catch {
            return .just(.failure(error))
        }
    }
}

// MARK: - Auxiliary -

extension AnyDatabase {
    public func transact<Model, R>(
        with request: QueryRequest<Model>,
        _ body: @escaping (QueryRequest<Model>.Output) throws -> R
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
                        try context.createInstance(Model.self, for: record)
                    }
                }
            )
            
            return try body(queryResult)
        }
    }
    
    public func transactSynchronously<R>(
        _ body: @escaping (AnyLocalTransaction) throws -> R
    ) throws -> R {
        let executor = try transactionExecutor()
        
        return try executor.executeSynchronously { transaction in
            let localTransaction = AnyLocalTransaction(
                transaction: .init(erasing: transaction),
                _SwiftDB_taskContext: _SwiftDB_TaskContext.defaultContext(for: self)
            )
            
            return try body(localTransaction)
        }
    }
    
    func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> AnyTask<QueryRequest<Model>.Output, Error> {
        return PassthroughTask<QueryRequest<Model>.Output, Error> { attemptToFulfill in
            Task {
                do {
                    try await self.transact(with: request) { result in
                        attemptToFulfill(.success(result))
                    }
                } catch {
                    attemptToFulfill(.failure(error))
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