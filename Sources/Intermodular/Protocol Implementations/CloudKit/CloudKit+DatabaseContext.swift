//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CloudKit {
    final class DatabaseContext {
        var ckContainer: CKContainer?
        var ckDatabase: CKDatabase
        
        var records: [CKRecord.ID: CKRecord?] = [:]
        
        init(database: CKDatabase, in container: CKContainer?) {
            self.ckContainer = container
            self.ckDatabase = database
        }
    }
}

extension _CloudKit.DatabaseContext: DatabaseContext {
    public typealias Object = _CloudKit.DatabaseObject
    public typealias ObjectType = String
    public typealias ObjectID = _CloudKit.DatabaseObject.ID
    
    func createObject(ofType type: String) throws -> Object {
        let record = CKRecord(recordType: type)
        
        records[record.recordID] = record
        
        return .init(base: record)
    }
    
    public func update(_ object: Object) throws {
        
    }
    
    public func delete(_ object: Object) throws {
        records[object.base.recordID] = nil
    }
    
    public func save() -> AnyTask<Void, SaveError> {
        let ckContainer = self.ckContainer
        let ckDatabase = self.ckDatabase
        let records = self.records
        
        return PassthroughTask { attemptToFullfill -> Void in
            let operation = CKModifyRecordsOperation(
                recordsToSave: records.compactMap({ $0.value }),
                recordIDsToDelete: records.lazy.filter({ $0.value == nil }).map({ $0.key })
            )
            
            operation.isAtomic = true
            operation.database = ckDatabase
            
            var conflicts: [DatabaseObjectMergeConflict<_CloudKit.DatabaseContext>]? = []
            
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
                    attemptToFullfill(.failure(error as! _CloudKit.DatabaseContext.SaveError))
                } else {
                    attemptToFullfill(.success(()))
                }
            }
            
            ckContainer?.add(operation)
            
            operation.start()
        }
        .eraseToAnyTask()
    }
}

extension DatabaseObjectMergeConflict where Context == _CloudKit.DatabaseContext {
    init(record: CKRecord, error: CKError) {
        self.source = .init(base: record)
    }
}
