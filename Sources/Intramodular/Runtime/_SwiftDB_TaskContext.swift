//
// Copyright (c) Vatsal Manot
//

import Swallow

struct _SwiftDB_TaskContext {
    private enum Error: Swift.Error {
        case transactionMissing
        case crossTransactionOperationDetected
    }

    let databaseContext: AnyDatabase.Context
    let _taskRuntime: (any _SwiftDB_TaskRuntime)?

    func validate(_ link: _SwiftDB_TaskRuntimeLink) throws {
        guard let _taskRuntime = _taskRuntime else {
            throw Error.transactionMissing
        }

        guard link.parentID == _taskRuntime.id else {
            throw Error.crossTransactionOperationDetected
        }
    }
}

extension _SwiftDB_TaskContext {
    static func defaultContext<Database: SwiftDB.Database>(
        for database: Database
    ) -> Self {
        let database = AnyDatabase(erasing: database)

        return .init(
            databaseContext: database.context,
            _taskRuntime: _DefaultTaskRuntime(databaseContext: database.context)
        )
    }

    static func defaultContext<Database: SwiftDB.Database>(
        fromDatabaseContext context: Database.Context
    ) -> Self {
        let databaseContext = context.eraseToAnyDatabaseContext()

        return .init(
            databaseContext: databaseContext,
            _taskRuntime: _DefaultTaskRuntime(databaseContext: databaseContext)
        )
    }
}

extension _SwiftDB_TaskContext {
    func _createTransactionScopedRecordProxy(
        for record: AnyDatabaseRecord,
        transaction: AnyDatabaseTransaction
    ) throws -> _DatabaseRecordProxy {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)

        return try .transactionScoped(
            _SwiftDB_taskContext: self,
            recordSchema: recordSchema,
            record: record,
            transaction: transaction
        )
    }

    func createTransactionScopedInstance<Instance>(
        _ instanceType: Instance.Type,
        for record: AnyDatabaseRecord,
        transaction: AnyDatabaseTransaction
    ) throws -> Instance {
        let instance = try _createTransactionScopedInstance(for: record, transaction: transaction)
        
        return try cast(instance, to: Instance.self)
    }

    private func _createTransactionScopedInstance(
        for record: AnyDatabaseRecord,
        transaction: AnyDatabaseTransaction
    ) throws -> any Entity {
        let schema = databaseContext.schema
        let entity = try databaseContext.schemaAdaptor.entity(forRecordType: record.recordType).unwrap()
        let entityType = try schema.entityType(for: entity)

        return try entityType.init(
            _databaseRecordProxy: _createTransactionScopedRecordProxy(
                for: record,
                transaction: transaction
            )
        )
    }
}

extension _SwiftDB_TaskContext {
    func _createSnapshotRecordProxy(
        for record: AnyDatabaseRecord
    ) throws -> _DatabaseRecordProxy {
        let recordSchema = try databaseContext.recordSchema(forRecordType: record.recordType)
        
        return try .snapshot(
            _SwiftDB_taskContext: self,
            recordSchema: recordSchema,
            record: record
        )
    }
    
    func createSnapshotInstance<Instance>(
        _ instanceType: Instance.Type,
        for record: AnyDatabaseRecord
    ) throws -> Instance {
        if instanceType == Any.self {
            return try cast(try _createSnapshotRecordProxy(for: record), to: Instance.self)
        } else if let instanceType = instanceType as? any Entity.Type {
            let instance = try instanceType.init(
                _databaseRecordProxy: try _createSnapshotRecordProxy(for: record)
            )
            
            return try cast(instance, to: Instance.self)
        } else {
            TODO.unimplemented
        }
    }
    
    func createSnapshotInstance(
        for record: AnyDatabaseRecord
    ) throws -> any Entity {
        let schema = databaseContext.schema
        let entity = try databaseContext.schemaAdaptor.entity(forRecordType: record.recordType).unwrap()
        let entityType = try schema.entityType(for: entity)
        
        return try entityType.init(
            _databaseRecordProxy: _createSnapshotRecordProxy(for: record)
        )
    }
}

// MARK: - Auxiliary -

extension _SwiftDB_TaskContext {
    final class _DefaultTaskRuntime: _SwiftDB_TaskRuntime {
        let context: AnyDatabase.Context
        let id = _SwiftDB_TaskRuntimeID()

        init(databaseContext: AnyDatabase.Context) {
            self.context = databaseContext
        }

        func scope<T>(_ body: (_SwiftDB_TaskContext) throws -> T) throws -> T {
            try _withSwiftDBTaskContext(.init(databaseContext: context, _taskRuntime: self)) {
                try body($0)
            }
        }

        func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T {
            try body()
        }
    }
}
