//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public final class LiveDatabaseAccess: DatabaseCRUDQ, DatabaseTransaction {
    private let taskQueue = TaskQueue()
    
    public var base: (any DatabaseTransaction)?
    
    public var isInitialized: Bool {
        base != nil
    }
    
    private var baseUnwrapped: any DatabaseTransaction {
        get throws {
            try base.unwrap()
        }
    }
    
    init(base: (any DatabaseTransaction)?) {
        self.base = base
    }
    
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        let result = try _withTransactionContext { _ in
            try baseUnwrapped.create(entityType)
        }
        
        taskQueue.add {
            try await self.commit()
        }
        
        return result
    }
    
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try _withTransactionContext { _ in
            try baseUnwrapped.delete(instance)
        }
        
        taskQueue.add {
            try await self.commit()
        }
    }
    
    public func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> Merge.AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try _withTransactionContext { _ in
                try baseUnwrapped.queryExecutionTask(for: request)
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func commit() async throws {
        try await taskQueue.perform {
            do {
                try await self.baseUnwrapped.commit()
            } catch {
                assertionFailure()
            }
        }
    }
    
    public func _scopeRecordMutation<T>(_ body: () throws -> T) rethrows -> T {
        defer {
            Task { @MainActor in
                try await commit()
            }
        }
        
        return try body()
    }
    
    public func _withTransactionContext<T>(_ body: (DatabaseTransactionContext) throws -> T) rethrows -> T {
        guard let base = try? baseUnwrapped else {
            fatalError()
        }
        
        return try base._withTransactionContext { context in
            let transactionContext = DatabaseTransactionContext(
                databaseContext: context.databaseContext,
                transaction: self
            )
            
            return try _SwiftDB_TaskLocalValues.$transactionContext.withValue(transactionContext) {
                try body(transactionContext)
            }
        }
    }
}
