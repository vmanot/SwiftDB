//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData {
    public struct DatabaseRecordContext {
        let base: NSManagedObjectContext
        
        init(base: NSManagedObjectContext) {
            self.base = base
        }
    }
}

extension _CoreData.DatabaseRecordContext: DatabaseRecordContext {
    public typealias Zone = _CoreData.Zone
    public typealias Record = _CoreData.DatabaseRecord
    public typealias RecordType = String
    public typealias RecordID = _CoreData.DatabaseRecord.ID
    
    public func createRecord(
        ofType type: RecordType,
        id: RecordID?,
        in zone: Zone?
    ) throws -> Record {
        let object = Record(base: NSEntityDescription.insertNewObject(forEntityName: type, into: base))
        
        if let zone = zone {
            base.assign(object.base, to: zone.base)
        }
        
        return object
    }
    
    public func recordID(from record: Record) throws -> RecordID {
        .init(base: record.base.objectID)
    }
    
    public func zone(for object: Record) throws -> Zone? {
        object.base.objectID.persistentStore.map({ Zone(base: $0) })
    }
    
    public func update(_ object: Record) throws {
        
    }
    
    public func delete(_ object: Record) throws {
        base.delete(object.base)
    }
    
    public func execute(_ request: FetchRequest) -> AnyTask<FetchRequest.Result, Error> {
        fatalError(reason: .unimplemented)
    }
    
    public func save() -> AnyTask<Void, SaveError> {
        guard base.hasChanges else {
            return .just(.success(()))
        }
        
        return PassthroughTask { attemptToFulfill in
            base.perform {
                do {
                    try base.save()
                    
                    attemptToFulfill(.success(()))
                } catch {
                    let error = error as NSError
                    
                    attemptToFulfill(.failure(
                        SaveError(
                            mergeConflicts: (error.userInfo["conflictList"] as? [NSMergeConflict]).map({ $0.map(DatabaseRecordMergeConflict.init) })
                        )
                    ))
                }
            }
        }
        .eraseToAnyTask()
    }
}

// MARK: - Helpers -

extension DatabaseRecordMergeConflict where Context == _CoreData.DatabaseRecordContext {
    fileprivate init(conflict: NSMergeConflict) {
        self.source = .init(base: conflict.sourceObject)
    }
}
