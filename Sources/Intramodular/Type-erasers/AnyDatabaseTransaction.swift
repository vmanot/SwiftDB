//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct AnyDatabaseTransaction: DatabaseTransaction {
    public typealias Database = AnyDatabase
    
    private let base: any DatabaseTransaction
    
    public init<Transaction: DatabaseTransaction>(erasing base: Transaction) {
        assert(!(base is AnyDatabaseTransaction))
        
        self.base = base
    }
    
    public func createRecord(
        withConfiguration configuration: RecordConfiguration
    ) throws -> Database.Record {
        try base._opaque_createRecord(withConfiguration: configuration)
    }
    
    public func updateRecord(
        _ recordID: AnyDatabaseRecord.ID,
        with update: RecordUpdate
    ) throws {
        try base._opaque_updateRecord(recordID, with: update)
    }
    
    public func executeSynchronously(
        _ request: AnyDatabase.ZoneQueryRequest
    ) throws -> AnyDatabase.ZoneQueryRequest.Result {
        try base._opaque_executeSynchronously(request)
    }
    
    public func delete(_ recordID: Database.Record.ID) throws {
        try base._opaque_delete(recordID)
    }
}

fileprivate extension DatabaseTransaction {
    func _opaque_createRecord(
        withConfiguration configuration: AnyDatabaseTransaction.RecordConfiguration
    ) throws -> AnyDatabase.Record {
        assert(!(self is AnyDatabaseTransaction))
        
        let record = try createRecord(
            withConfiguration: configuration._cast(to: RecordConfiguration.self)
        )
        
        return AnyDatabaseRecord(erasing: record)
    }
    
    func _opaque_updateRecord(
        _ recordID: AnyDatabaseRecord.ID,
        with update: AnyDatabaseTransaction.RecordUpdate
    ) throws {
        assert(!(self is AnyDatabaseTransaction))
        
        try updateRecord(
            recordID._cast(to: Database.Record.ID.self),
            with: try update._cast(to: RecordUpdate.self)
        )
    }
    
    func _opaque_executeSynchronously(
        _ request: AnyDatabase.ZoneQueryRequest
    ) throws -> AnyDatabase.ZoneQueryRequest.Result {
        assert(!(self is AnyDatabaseTransaction))
        
        return .init(_erasing: try executeSynchronously(try request._cast(to: Database.ZoneQueryRequest.self)))
    }
    
    func _opaque_delete(_ recordID: AnyDatabase.Record.ID) throws {
        assert(!(self is AnyDatabaseTransaction))
        
        return try delete(recordID._cast(to: Database.Record.ID.self))
    }
}
