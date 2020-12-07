//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CoreData {
    struct DatabaseObjectContext {
        let base: NSManagedObjectContext
    }
}

extension _CoreData.DatabaseObjectContext: DatabaseObjectContext {
    typealias Zone = _CoreData.Zone
    typealias Object = _CoreData.DatabaseObject
    typealias ObjectType = String
    typealias ObjectID = _CoreData.DatabaseObject.ID
    
    func createObject(ofType type: ObjectType, name: String?, in zone: Zone?) throws -> Object {
        let object = Object(base: NSEntityDescription.insertNewObject(forEntityName: type, into: base))
        
        if let zone = zone {
            base.assign(object.base, to: zone.base)
        }
        
        return object
    }
   
    func zone(for object: Object) throws -> Zone? {
        object.base.objectID.persistentStore.map({ Zone(base: $0) })
    }
    
    func update(_ object: Object) throws {
        
    }
    
    func delete(_ object: Object) throws {
        base.delete(object.base)
    }
    
    func save() -> AnyTask<Void, SaveError> {
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
                            mergeConflicts: (error.userInfo["conflictList"] as? [NSMergeConflict]).map({ $0.map(DatabaseObjectMergeConflict.init) })
                        )
                    ))
                }
            }
        }
        .eraseToAnyTask()
    }
}

extension DatabaseObjectMergeConflict where Context == _CoreData.DatabaseObjectContext {
    init(conflict: NSMergeConflict) {
        self.source = .init(base: conflict.sourceObject)
    }
}
