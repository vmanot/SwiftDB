//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Runtime
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
        
        /// Check if the context needs to publish changes, publish if necessary.
        @objc private func managedObjectContextObjectsDidChange(notification: NSNotification) {
            guard let userInfo = notification.userInfo else {
                return
            }
            
            var triggerObjectWillChange: Bool = false
            
            if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
                triggerObjectWillChange = true
            }
            
            if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
                triggerObjectWillChange = true
            }
            
            if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {
                triggerObjectWillChange = true
            }
            
            if triggerObjectWillChange {
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
            rawObject: NSEntityDescription.insertNewObject(
                forEntityName: configuration.recordType.rawValue,
                into: nsManagedObjectContext
            )
        )
        
        if let zone = configuration.zone {
            nsManagedObjectContext.assign(object.rawObject, to: zone.persistentStore)
        }
        
        return object
    }
    
    public func instantiate<Model: Entity>(_ type: Model.Type, from record: Record) throws -> Model {
        let schema = try self.parent.unwrap().schema
        
        if let entityType = schema.entityNameToTypeMap[record.rawObject.entity.name]?.value {
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
        .init(managedObjectID: record.rawObject.objectID)
    }
    
    public func zone(for object: Record) throws -> Zone? {
        object.rawObject.objectID.persistentStore.map({ Zone(persistentStore: $0) })
    }
    
    public func delete(_ object: Record) throws {
        nsManagedObjectContext.delete(object.rawObject)
    }
    
    public func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error> {
        do {
            if request.sortDescriptors.isNil {
                return Task {
                    try await nsManagedObjectContext.perform { [nsManagedObjectContext] in
                        try nsManagedObjectContext
                            .fetch(try request.toNSFetchRequest(context: self))
                            .map({ Record(rawObject: $0) })
                    }
                }
                .publisher()
                .map({ ZoneQueryRequest.Result(records: $0) })
                .convertToTask()
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
                    
                    attemptToFulfill(.success(ZoneQueryRequest.Result(records: fetchedResultsController.fetchedObjects?.map({ Record(rawObject: $0) }))))
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
        return Task { @Sendable in
            @Sendable
            func save() -> Result<Void, SaveError> {
                do {
                    try self.nsManagedObjectContext.save()

                    return .success(())
                } catch {
                    let error = error as NSError
                    
                    return .failure(
                        SaveError(
                            description: error.description,
                            mergeConflicts: (error.userInfo["conflictList"] as? [NSMergeConflict]).map({ $0.map(DatabaseRecordMergeConflict.init) })
                        )
                    )
                }
            }
            
            guard nsManagedObjectContext.hasChanges else {
                return .success(())
            }

            if nsManagedObjectContext.concurrencyType == .mainQueueConcurrencyType {
                return await MainActor.run {
                    save()
                }
            } else {
                return save()
            }
        }
        .convertToObservableTask()
    }
    
    public func zoneQueryRequest<Model>(
        from queryRequest: QueryRequest<Model>
    ) throws -> ZoneQueryRequest {
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
        self.source = .init(rawObject: conflict.sourceObject)
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
        result.affectedStores = context.affectedStores?.filter({ (self.filters.zones?.contains(_CoreData.Database.Zone(persistentStore: $0).id) ?? false) })
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
