//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Swallow
import Task

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
    public typealias Object = _CloudKit.DatabaseRecord
    public typealias RecordType = String
    public typealias RecordID = _CloudKit.DatabaseRecord.ID
    public typealias Zone = _CloudKit.DatabaseZone
    
    public func createRecord(ofType type: RecordType, name: String?, in zone: Zone?) throws -> Object {
        let record: CKRecord
        
        if let zone = zone {
            record = CKRecord(
                recordType: type,
                recordID: .init(
                    recordName: name ?? UUID().uuidString,
                    zoneID: .init(zoneName: zone.name, ownerName: zone.ownerName)
                )
            )
        } else {
            record = CKRecord(
                recordType: type,
                recordID: .init(recordName: name ?? UUID().uuidString)
            )
        }
        
        records[record.recordID] = record
        
        return .init(base: record)
    }
    
    public func zone(for object: Object) throws -> Zone? {
        zones.lazy
            .map({ $0.base })
            .first(where: { $0.zoneID == object.base.recordID.zoneID })
            .map({ Zone(base: $0) })
    }
    
    public func update(_ object: Object) throws {
        
    }
    
    public func delete(_ object: Object) throws {
        records[object.base.recordID] = nil
    }
    
    public func execute(_ request: FetchRequest) -> AnyTask<FetchRequest.Result, Error> {
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
}

extension DatabaseRecordMergeConflict where Context == _CloudKit.DatabaseRecordContext {
    init(record: CKRecord, error: CKError) {
        self.source = .init(base: record)
    }
}
