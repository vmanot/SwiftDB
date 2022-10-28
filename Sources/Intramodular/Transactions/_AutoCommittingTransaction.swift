//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// A transaction that automatically commits any record mutations made within its scope.
final class _AutoCommittingTransaction: _TransactionInterposer, ObservableObject {
    private let commitQueue = TaskQueue(policy: .cancelPreviousAction)
    
    let base: any _Transaction
    
    var interposedTransactionID: _TransactionID {
        base.id
    }
    
    var id: _TransactionID {
        base.id
    }
    
    init(base: any _Transaction) {
        if base is _AutoCommittingTransaction {
            assertionFailure()
        }
        
        self.base = base
    }
    
    func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        try scope { _ in
            let instance = try base.create(entityType)
            
            commitQueue.add {
                try await self.commit()
            }
            
            return instance
        }
    }
    
    func delete<Instance: Entity>(_ instance: Instance) throws {
        try scope { _ in
            try base.delete(instance)
            
            commitQueue.add {
                try await self.commit()
            }
        }
    }
    
    func queryExecutionTask<Model>(
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
    
    func querySubscription<Model>(for request: QueryRequest<Model>) throws -> QuerySubscription<Model> {
        return try scope { _ in
            try base.querySubscription(for: request)
        }
    }
    
    func commit() async throws {
        try await commitQueue.perform {
            try await Task.sleep(.milliseconds(50))
            
            try Task.checkCancellation()
            
            do {
                try await self.base.commit()
            } catch {
                assertionFailure()
            }
        }
    }
    
    func _scopeRecordMutation<T>(_ body: () throws -> T) rethrows -> T {
        defer {
            Task { @MainActor in
                try await commit()
            }
        }
        
        return try body()
    }
    
    func scope<T>(_ operation: (_SwiftDB_RuntimeTaskContext) throws -> T) throws -> T {
        try base.scope { context in
            let transactionContext = _SwiftDB_RuntimeTaskContext(
                databaseContext: context.databaseContext,
                transaction: self
            )
            
            return try _withRuntimeTaskContext(transactionContext) { context in
                try operation(context)
            }
        }
    }
}
