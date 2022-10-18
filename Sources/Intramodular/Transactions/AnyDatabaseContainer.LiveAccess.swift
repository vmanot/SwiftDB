//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

extension AnyDatabaseContainer {
    public final class LiveAccess: ObservableObject {
        private let taskQueue = TaskQueue()
        
        @Published private var base: (any DatabaseTransaction)?
        
        public var id: any Hashable {
            base?.id ?? AnyHashable(base?.id) // BAD HACK
        }
        
        public var isInitialized: Bool {
            base != nil
        }
        
        private var baseUnwrapped: any DatabaseTransaction {
            get throws {
                try base.unwrap()
            }
        }
        
        public init() {
            
        }
        
        public func setBaseTransaction(_ transaction: (any DatabaseTransaction)?) {
            self.base = transaction.map {
                _AutoCommittingDatabaseTransaction(base: $0)
            }
        }
    }
}

extension AnyDatabaseContainer.LiveAccess: DatabaseCRUDQ {
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        let instance = try baseUnwrapped.create(entityType)
        
        return instance
    }
    
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try baseUnwrapped.delete(instance)
    }
    
    public func queryExecutionTask<Model>(
        for request: QueryRequest<Model>
    ) -> Merge.AnyTask<QueryRequest<Model>.Output, Error> {
        do {
            return try baseUnwrapped.queryExecutionTask(for: request)
        } catch {
            return .failure(error)
        }
    }
    
    public func querySubscription<Model>(for request: QueryRequest<Model>) throws -> QuerySubscription<Model> {
        try baseUnwrapped.querySubscription(for: request)
    }
}
