//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

extension _CoreData {
    public final class DatabaseRecordContext: ObservableObject {
        weak var parent: Database?

        let notificationCenter: NotificationCenter = .default
        let nsManagedObjectContext: NSManagedObjectContext
        let affectedStores: [NSPersistentStore]?
        
        init(
            parent: Database,
            managedObjectContext: NSManagedObjectContext,
            affectedStores: [NSPersistentStore]?
        ) {
            self.parent = parent
            self.nsManagedObjectContext = managedObjectContext
            self.affectedStores = affectedStores
            
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextWillSave, object: managedObjectContext)
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextDidSave, object: managedObjectContext)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc private func managedObjectContextObjectsDidChange(notification: NSNotification) {
            guard let userInfo = notification.userInfo else {
                return
            }
            
            if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
                objectWillChange.send()
            }
            
            if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
                objectWillChange.send()
            }
            
            if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
                objectWillChange.send()
            }
        }
    }
}

extension _CoreData.DatabaseRecordContext: DatabaseRecordContext {
    public typealias Zone = _CoreData.Database.Zone
    public typealias Record = _CoreData.DatabaseRecord
    public typealias RecordType = _CoreData.DatabaseRecord.RecordType
    public typealias RecordID = _CoreData.DatabaseRecord.ID
    
    public func createRecord(
        withConfiguration configuration: RecordConfiguration,
        context: RecordCreateContext
    ) throws -> Record {
        let object = Record(
            base: NSEntityDescription.insertNewObject(
                forEntityName: configuration.recordType.rawValue,
                into: nsManagedObjectContext
            )
        )
        
        if let zone = configuration.zone {
            nsManagedObjectContext.assign(object.base, to: zone.persistentStore)
        }
        
        return object
    }

    public func instantiate<Model: Entity>(_ type: Model.Type, from record: Record) throws -> Model {
        let schema = try self.parent.unwrap().schema

        if let entityType = schema.entityNameToTypeMap[record.base.entity.name]?.value {
            return try cast(entityType.init(_underlyingDatabaseRecord: record), to: Model.self)
        } else {
            assertionFailure()

            return type.init()
        }
    }
    
    public func getUnderlyingRecord<Instance: Entity>(
        from instance: Instance
    ) throws -> Record {
        try cast(instance._underlyingDatabaseRecord.unwrap(), to: Record.self)
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
    
    public func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error> {
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
            
            return PassthroughTask<ZoneQueryRequest.Result, Error> { attemptToFulfill -> Void in
                do {
                    try fetchedResultsController.performFetch()
                    
                    attemptToFulfill(.success(ZoneQueryRequest.Result(records: fetchedResultsController.fetchedObjects?.map({ Record(base: $0) }))))
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

    public func zoneQueryRequest<Model>(from queryRequest: QueryRequest<Model>) throws -> ZoneQueryRequest {
        let parent = try parent.unwrap()

        return try ZoneQueryRequest(
            filters: .init(
                zones: nil,
                recordTypes: [.init(rawValue: parent.schema.entity(forModelType: Model.self).unwrap().name)],
                includesSubentities: true
            ),
            predicate: queryRequest.predicate.map({ predicate in
                DatabaseZoneQueryPredicate(
                    try predicate.toNSPredicate(
                        context: .init(
                            expressionConversionContext: .init(
                                keyPathConversionStrategy: .custom(parent.runtime.convertEntityKeyPathToString),
                                keyPathPrefix: nil
                            )
                        )
                    )
                )
            }),
            sortDescriptors: queryRequest.sortDescriptors,
            cursor: nil,
            limit: queryRequest.fetchLimit
        )
    }
}

// MARK: - Helpers -

fileprivate extension DatabaseRecordMergeConflict where Context == _CoreData.DatabaseRecordContext {
    init(conflict: NSMergeConflict) {
        self.source = .init(base: conflict.sourceObject)
    }
}

fileprivate extension DatabaseZoneQueryRequest where Context == _CoreData.DatabaseRecordContext {
    func toNSFetchRequest(context: Context) throws -> NSFetchRequest<NSManagedObject> {
        guard let recordType = filters.recordTypes.first else {
            throw _CoreData.DatabaseRecordContext.DatabaseZoneQueryRequestError.recordTypeRequired
        }
        
        guard filters.recordTypes.count == 1 else {
            throw _CoreData.DatabaseRecordContext.DatabaseZoneQueryRequestError.multipleRecordTypesUnsupported
        }
        
        
        let result = NSFetchRequest<NSManagedObject>(entityName: recordType.rawValue)
        
        switch self.predicate {
            case .related(_, _):
                TODO.unimplemented
            case let ._nsPredicate(predicate):
                result.predicate = predicate
            case .none:
                result.predicate = nil
        }
        
        result.sortDescriptors = self.sortDescriptors.map({ $0.map({ $0 as NSSortDescriptor }) })
        result.affectedStores = context.affectedStores?.filter({ (self.filters.zones?.contains($0.identifier) ?? false) })
        result.includesSubentities = filters.includesSubentities
        
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

extension _CoreData.DatabaseRecordContext {
    enum DatabaseZoneQueryRequestError: Swift.Error {
        case recordTypeRequired
        case multipleRecordTypesUnsupported
    }
}
