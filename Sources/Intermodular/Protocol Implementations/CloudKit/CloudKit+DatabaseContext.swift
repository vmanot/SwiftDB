//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Swallow
import Task

extension _CloudKit {
    final class DatabaseObjectContext {
        var ckContainer: CKContainer?
        var ckDatabase: CKDatabase
        var ckRecordZones: [CKRecordZone]
        
        var records: [CKRecord.ID: CKRecord?] = [:]
        
        init(container: CKContainer?, database: CKDatabase, zones: [CKRecordZone]) {
            self.ckContainer = container
            self.ckDatabase = database
            self.ckRecordZones = zones
        }
    }
}

extension _CloudKit.DatabaseObjectContext: DatabaseObjectContext {
    typealias Object = _CloudKit.DatabaseObject
    typealias ObjectType = String
    typealias ObjectID = _CloudKit.DatabaseObject.ID
    typealias Zone = _CloudKit.Zone
    
    func createObject(ofType type: ObjectType, name: String?, in zone: Zone?) throws -> Object {
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
    
    func zone(for object: Object) throws -> Zone? {
        ckRecordZones
            .first(where: { $0.zoneID == object.base.recordID.zoneID })
            .map({ Zone(base: $0) })
    }
    
    func update(_ object: Object) throws {
        
    }
    
    func delete(_ object: Object) throws {
        records[object.base.recordID] = nil
    }
    
    func save() -> AnyTask<Void, SaveError> {
        let ckDatabase = self.ckDatabase
        let records = self.records
        
        return PassthroughTask { attemptToFullfill -> Void in
            let operation = CKModifyRecordsOperation(
                recordsToSave: records.compactMap({ $0.value }),
                recordIDsToDelete: records.lazy.filter({ $0.value == nil }).map({ $0.key })
            )
            
            operation.isAtomic = true
            operation.database = ckDatabase
            
            var conflicts: [DatabaseObjectMergeConflict<_CloudKit.DatabaseObjectContext>]? = []
            
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
                    attemptToFullfill(.failure(error as! _CloudKit.DatabaseObjectContext.SaveError))
                } else {
                    attemptToFullfill(.success(()))
                }
            }
            
            ckDatabase.add(operation)
        }
        .eraseToAnyTask()
    }
}

extension DatabaseObjectMergeConflict where Context == _CloudKit.DatabaseObjectContext {
    init(record: CKRecord, error: CKError) {
        self.source = .init(base: record)
    }
}
