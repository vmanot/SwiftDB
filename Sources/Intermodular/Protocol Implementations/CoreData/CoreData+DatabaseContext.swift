//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CoreData {
    struct DatabaseContext {
        let base: NSManagedObjectContext
    }
}

extension _CoreData.DatabaseContext: DatabaseContext {
    public typealias Object = _CoreData.DatabaseObject
    public typealias ObjectID = _CoreData.DatabaseObject.ID
    
    func createObject(ofType type: String) throws -> Object {
        return .init(base: NSEntityDescription.insertNewObject(forEntityName: type, into: base))
    }
    
    public func update(_ object: Object) throws {
        
    }
    
    public func delete(_ object: Object) throws {
        base.delete(object.base)
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
                            mergeConflicts: (error.userInfo["conflictList"] as? [NSMergeConflict]).map({ $0.map(DatabaseObjectMergeConflict.init) })
                        )
                    ))
                }
            }
        }
        .eraseToAnyTask()
    }
}

extension DatabaseObjectMergeConflict where Context == _CoreData.DatabaseContext {
    init(conflict: NSMergeConflict) {
        self.source = .init(base: conflict.sourceObject)
    }
}
