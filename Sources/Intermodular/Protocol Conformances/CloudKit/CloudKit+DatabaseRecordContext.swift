//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit {
    public final class DatabaseRecordContext: @unchecked Sendable {
        var ckContainer: CKContainer?
        var ckDatabase: CKDatabase
        var zones: [Zone]
        
        var records: [CKRecord.ID: CKRecord?] = [:]
        
        public let databaseContext: _CloudKit.Database.Context
        
        init(parent: _CloudKit.Database, zones: [Zone]) {
            self.ckContainer = parent.ckContainer
            self.ckDatabase = parent.ckDatabase
            self.zones = zones
            self.databaseContext = parent.context
        }
    }
}

extension _CloudKit.DatabaseRecordContext: DatabaseRecordContext {
    public typealias Database = _CloudKit.Database
    public typealias Record = _CloudKit.DatabaseRecord
    public typealias Zone = _CloudKit.DatabaseZone
    
    public func createRecord(
        withConfiguration configuration: RecordConfiguration,
        context: RecordCreateContext
    ) throws -> Record {
        let record: CKRecord
        
        record = CKRecord(
            recordType: configuration.recordType,
            recordID: CKRecord.ID(
                recordName: configuration.recordID?.rawValue,
                zoneID: configuration.zone.map {
                    CKRecordZone.ID(zoneName: $0.name, ownerName: $0.ownerName)
                }
            )
        )
        
        records[record.recordID] = record
        
        return .init(ckRecord: record)
    }
    
    public func delete(_ object: Record) throws {
        records[object.ckRecord.recordID] = nil
    }
    
    public func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error> {
        fatalError(reason: .unimplemented)
    }
    
    public final class QuerySubscription: DatabaseQuerySubscription {
        fileprivate init() {
            TODO.unimplemented
        }
    }
    
    public func querySubscription(
        for request: ZoneQueryRequest
    ) throws -> QuerySubscription {
        TODO.unimplemented
    }
    
    public func save() -> AnyTask<Void, SaveError> {
        let ckDatabase = self.ckDatabase
        let records = self.records
        
        return PassthroughTask { attemptToFullfill -> Void in
            let operation = CKModifyRecordsOperation(
                recordsToSave: records.compactMap({ $0.value }),
                recordIDsToDelete: records.lazy.filter({ $0.value == nil }).map({ $0.key })
            )
            
            operation.isAtomic = true
            operation.database = ckDatabase
            
            /*var conflicts: [DatabaseRecordMergeConflict<_CloudKit.DatabaseRecordContext>]? = []
             
             operation.perRecordProgressBlock = { record, progress in
             
             }
             
             operation.perRecordCompletionBlock = { record, error in
             if let error = error as? CKError {
             if error.code == CKError.serverRecordChanged {
             conflicts ??= []
             conflicts?.append(.init(record: record, error: error))
             }
             }
             }
             
             operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecords, error in
             if let error = error {
             attemptToFullfill(.failure(error as! _CloudKit.DatabaseRecordContext.SaveError))
             } else {
             attemptToFullfill(.success(()))
             }
             }*/
            
            ckDatabase.add(operation)
            
            TODO.unimplemented
        }
        .eraseToAnyTask()
    }
}

extension DatabaseRecordMergeConflict where Context == _CloudKit.DatabaseRecordContext {
    init(record: CKRecord, error: CKError) {
        self.source = .init(ckRecord: record)
    }
}
