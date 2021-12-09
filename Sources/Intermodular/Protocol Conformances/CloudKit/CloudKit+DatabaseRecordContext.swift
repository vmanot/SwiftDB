//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit {
    public final class DatabaseRecordContext {
        var ckContainer: CKContainer?
        var ckDatabase: CKDatabase
        var zones: [Zone]
        
        var records: [CKRecord.ID: CKRecord?] = [:]
        
        init(container: CKContainer?, database: CKDatabase, zones: [Zone]) {
            self.ckContainer = container
            self.ckDatabase = database
            self.zones = zones
        }
    }
}

extension _CloudKit.DatabaseRecordContext: DatabaseRecordContext {
    public typealias Record = _CloudKit.DatabaseRecord
    public typealias RecordType = String
    public typealias RecordID = _CloudKit.DatabaseRecord.ID
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
    
    public func recordID(from record: Record) throws -> Record.ID {
        .init(rawValue: record.base.recordID.recordName)
    }
    
    public func zone(for object: Record) throws -> Zone? {
        zones.lazy
            .map({ $0.ckRecordZone })
            .first(where: { $0.zoneID == object.base.recordID.zoneID })
            .map({ Zone(recordZone: $0) })
    }
    
    public func delete(_ object: Record) throws {
        records[object.base.recordID] = nil
    }
    
    public func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error> {
        fatalError(reason: .unimplemented)
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
            
            var conflicts: [DatabaseRecordMergeConflict<_CloudKit.DatabaseRecordContext>]? = []
            
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
            }
            
            ckDatabase.add(operation)
        }
        .eraseToAnyTask()
    }
    
    public func zoneQueryRequest<Model>(from queryRequest: QueryRequest<Model>) throws -> ZoneQueryRequest {
        fatalError()
    }
}

extension DatabaseRecordMergeConflict where Context == _CloudKit.DatabaseRecordContext {
    init(record: CKRecord, error: CKError) {
        self.source = .init(ckRecord: record)
    }
}
