//
// Copyright (c) Vatsal Manot
//

import API
import Swallow

public struct AnyLocalTransaction: LocalDatabaseCRUDQ {
    private let _SwiftDB_taskContext: _SwiftDB_TaskContext
    private let transaction: AnyDatabaseTransaction
    
    public init(
        transaction: AnyDatabaseTransaction,
        _SwiftDB_taskContext: _SwiftDB_TaskContext
    ) {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
        self.transaction = transaction
    }
    
    private func scope<T>(_ operation: (_SwiftDB_TaskContext) throws -> T) throws -> T {
        try _withSwiftDBTaskContext(_SwiftDB_taskContext) { context in
            try operation(context)
        }
    }
}

extension AnyLocalTransaction {
    public func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance {
        return try scope { context in
            let entity = try context.databaseContext.schema.entity(forModelType: entityType).unwrap()
            
            let record = try transaction.createRecord(
                withConfiguration: .init(
                    recordType: context.databaseContext.schemaAdaptor.recordType(for: entity.id),
                    recordID: nil,
                    zone: nil
                )
            )
            
            let recordContainer = try _DatabaseRecordProxy(
                _SwiftDB_taskContext: context,
                recordSchema: entity,
                record: record
            )
            
            return try entityType.init(from: recordContainer)
        }
    }
    
    public func execute<Model>(
        _ request: QueryRequest<Model>
    ) throws -> QueryRequest<Model>.Output {
        let results = try transaction.executeSynchronously(
            DatabaseZoneQueryRequest(
                from: request,
                databaseContext: _SwiftDB_taskContext.databaseContext
            )
        )
        
        return QueryRequest<Model>.Output(
            results: try results.records?.map {
                try _SwiftDB_taskContext.createInstance(Model.self, for: $0)
            } ?? []
        )
    }
    
    public func delete<Instance: Entity>(_ instance: Instance) throws {
        try scope { context in
            try transaction.delete(AnyDatabaseRecord(from: instance))
        }
    }
}
