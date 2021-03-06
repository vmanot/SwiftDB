//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

extension _CoreData {
    public final class DatabaseRecordContext {
        let nsManagedObjectContext: NSManagedObjectContext
        let affectedStores: [NSPersistentStore]?
        
        init(
            managedObjectContext: NSManagedObjectContext,
            affectedStores: [NSPersistentStore]?
        ) {
            self.nsManagedObjectContext = managedObjectContext
            self.affectedStores = affectedStores
        }
    }
}

extension _CoreData.DatabaseRecordContext: DatabaseRecordContext {
    public typealias Zone = _CoreData.Database.Zone
    public typealias Record = _CoreData.DatabaseRecord
    public typealias RecordType = String
    public typealias RecordID = _CoreData.DatabaseRecord.ID
    
    public func createRecord(
        withConfiguration configuration: RecordConfiguration,
        context: RecordCreateContext
    ) throws -> Record {
        let object = Record(
            base: NSEntityDescription.insertNewObject(
                forEntityName: configuration.recordType,
                into: nsManagedObjectContext
            )
        )
        
        if let zone = configuration.zone {
            nsManagedObjectContext.assign(object.base, to: zone.persistentStore)
        }
        
        return object
    }
    
    public func recordID(from record: Record) throws -> RecordID {
        .init(managedObjectID: record.base.objectID)
    }
    
    public func zone(for object: Record) throws -> Zone? {
        object.base.objectID.persistentStore.map({ Zone(persistentStore: $0) })
    }
    
    public func delete(_ object: Record) throws {
        nsManagedObjectContext.delete(object.base)
    }
    
    public func execute(_ request: FetchRequest) -> AnyTask<FetchRequest.Result, Error> {
        do {
            if request.sortDescriptors.isNil {
                return .success(.init(records: try nsManagedObjectContext.fetch(try request.toNSFetchRequest(context: self)) .map({ Record(base: $0) })))
            }
            
            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: try request.toNSFetchRequest(context: self),
                managedObjectContext: nsManagedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return PassthroughTask<FetchRequest.Result, Error> { attemptToFulfill -> Void in
                do {
                    try fetchedResultsController.performFetch()
                    
                    attemptToFulfill(.success(FetchRequest.Result(records: fetchedResultsController.fetchedObjects?.map({ Record(base: $0) }))))
                } catch {
                    attemptToFulfill(.failure(error))
                }
            }
            .eraseToAnyTask()
        } catch {
            return .failure(error)
        }
    }
    
    public func save() -> AnyTask<Void, SaveError> {
        guard nsManagedObjectContext.hasChanges else {
            return .just(.success(()))
        }
        
        return PassthroughTask { attemptToFulfill -> () in
            func save() {
                do {
                    try self.nsManagedObjectContext.save()
                    
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
            
            if self.nsManagedObjectContext.concurrencyType == .mainQueueConcurrencyType {
                save()
            } else {
                self.nsManagedObjectContext.perform {
                    save()
                }
            }
        }
        .eraseToAnyTask()
    }
}

// MARK: - Helpers -

fileprivate extension DatabaseRecordMergeConflict where Context == _CoreData.DatabaseRecordContext {
    init(conflict: NSMergeConflict) {
        self.source = .init(base: conflict.sourceObject)
    }
}

fileprivate extension DatabaseFetchRequest where Context == _CoreData.DatabaseRecordContext {
    func toNSFetchRequest(context: Context) throws -> NSFetchRequest<NSManagedObject> {
        let result = NSFetchRequest<NSManagedObject>(entityName: try recordType.unwrap())
        
        result.predicate = self.predicate
        result.sortDescriptors = self.sortDescriptors.map({ $0.map({ $0 as NSSortDescriptor }) })
        result.affectedStores = context.affectedStores?.filter({ (self.zones?.contains($0.identifier) ?? false) })
        result.includesSubentities = includesSubentities
        
        if let cursor = cursor {
            if case .offset(let offset) = cursor {
                result.fetchOffset = offset
            } else {
                throw Never.Reason.illegal
            }
        }
        
        if let fetchLimit = fetchLimit {
            switch fetchLimit {
                case .cursor(.offset(let offset)):
                    result.fetchLimit = offset
                case .none:
                    result.fetchLimit = 0
                default:
                    fatalError(reason: .unimplemented)
            }
        }
        
        return result
    }
}
