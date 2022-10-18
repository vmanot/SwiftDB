//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

final class _AutoCommittingDatabaseTransaction: DatabaseTransaction, ObservableObject {
    private let taskQueue = TaskQueue()
    
    let base: any DatabaseTransaction
    
    var id: DatabaseTransactionID {
        base.id
    }
    
    init(base: any DatabaseTransaction) {
        self.base = base
    }
    
    func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        try scope { _ in
            let instance = try base.create(entityType)
            
            taskQueue.add {
                try await self.commit()
            }
            
            return instance
        }
    }
    
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try scope { _ in
            try base.delete(instance)
            
            taskQueue.add {
                try await self.commit()
            }
        }
    }
    
    public func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> Merge.AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try scope { _ in
                base.queryExecutionTask(for: request)
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func querySubscription<Model>(for request: QueryRequest<Model>) throws -> QuerySubscription<Model> {
        return try scope { _ in
            try base.querySubscription(for: request)
        }
    }
    
    public func commit() async throws {
        try await taskQueue.perform {
            do {
                try await self.base.commit()
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
    
    public func scope<T>(_ operation: (DatabaseTransactionContext) throws -> T) throws -> T {
        try base.scope { context in
            let transactionContext = DatabaseTransactionContext(
                databaseContext: context.databaseContext,
                transaction: self
            )
            
            return try withDatabaseTransactionContext(transactionContext) { context in
                try operation(context)
            }
        }
    }
}
