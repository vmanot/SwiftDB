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
        withConfiguration configuration: RecordConfiguration
    ) throws -> Record {
        let record: CKRecord
        
        if let zone = configuration.zone {
            record = CKRecord(
                recordType: configuration.recordType,
                recordID: .init(
                    recordName: configuration.recordID?.rawValue ?? UUID().uuidString,
                    zoneID: .init(zoneName: zone.name, ownerName: zone.ownerName)
                )
            )
        } else {
            record = CKRecord(
                recordType: configuration.recordType,
                recordID: .init(recordName: configuration.recordID?.rawValue ?? UUID().uuidString)
            )
        }
        
        records[record.recordID] = record
        
        return .init(ckRecord: record)
    }
    
    public func recordID(from record: Record) throws -> Record.ID {
        .init(rawValue: record.base.recordID.recordName)
    }
    
    public func zone(for object: Record) throws -> Zone? {
        zones.lazy
            .map({ $0.base })
            .first(where: { $0.zoneID == object.base.recordID.zoneID })
            .map({ Zone(base: $0) })
    }
    
    public func update(_ object: Record) throws {
        
    }
    
    public func delete(_ object: Record) throws {
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
        self.source = .init(ckRecord: record)
    }
}
