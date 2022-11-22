//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Runtime
import Swallow

extension _CoreData {
    public final class DatabaseRecordSpace: ObservableObject, @unchecked Sendable {
        private let cancellables = Cancellables()

        public let databaseContext: DatabaseContext<Database>

        let notificationCenter: NotificationCenter = .default
        let nsManagedObjectContext: NSManagedObjectContext
        let affectedStores: [_CoreData.Database.Zone.ID]?
        let managedObjectsObserver: NSManagedObjectContext.ObjectsObserver

        init(
            databaseContext: DatabaseContext<Database>,
            managedObjectContext: NSManagedObjectContext,
            affectedStores: [_CoreData.Database.Zone.ID]?
        ) {
            self.databaseContext = databaseContext
            self.nsManagedObjectContext = managedObjectContext
            self.affectedStores = affectedStores
            self.managedObjectsObserver = .init(managedObjectContext: managedObjectContext)

            self.managedObjectsObserver.sink { events in
                do {
                    var insertedObjects: [NSManagedObject] = []

                    for event in events {
                        switch event {
                            case .inserted(let object):
                                insertedObjects.append(object)
                            default:
                                break
                        }
                    }

                    try managedObjectContext.obtainPermanentIDs(for: insertedObjects)
                } catch {
                    assertionFailure(error)
                }

                if !events.isEmpty {
                    MainThreadScheduler.shared.schedule {
                        self.objectWillChange.send()
                    }
                }
            }
            .store(in: cancellables)
        }
    }
}

extension _CoreData.DatabaseRecordSpace: DatabaseRecordSpace {
    public typealias Database = _CoreData.Database
    public typealias Zone = _CoreData.Database.Zone
    public typealias Record = _CoreData.DatabaseRecord
    public typealias RecordType = _CoreData.DatabaseRecord.RecordType
    public typealias QuerySubscription = _CoreData.Database.QuerySubscription

    public func createRecord(
        withConfiguration configuration: RecordConfiguration
    ) throws -> Record {
        let object = try Record(
            rawObject: NSEntityDescription.insertNewObject(
                forEntityName: configuration.recordType.unwrap().rawValue,
                into: nsManagedObjectContext
            )
        )

        if let zone = configuration.zone {
            nsManagedObjectContext.assign(object.rawObject, to: try nsPersistentStore(for: zone.id))
        }

        return object
    }

    public func delete(_ object: Record) throws {
        nsManagedObjectContext.delete(object.rawObject)
    }

    public func execute(_ request: Database.ZoneQueryRequest) -> AnyTask<Database.ZoneQueryRequest.Result, Error> {
        do {
            let nsFetchRequests = try request.toNSFetchRequests(recordSpace: self)

            if request.sortDescriptors.isNil {
                return Task {
                    try await nsManagedObjectContext.perform { [nsManagedObjectContext] in
                        return try nsFetchRequests.flatMap { fetchRequest in
                            try nsManagedObjectContext
                                .fetch(fetchRequest)
                                .map({ Record(rawObject: $0) })
                        }
                    }
                }
                .publisher()
                .map({ Database.ZoneQueryRequest.Result(records: $0) })
                .convertToTask()
            }

            return PassthroughTask<Database.ZoneQueryRequest.Result, Error> { attemptToFulfill -> Void in
                do {
                    var fetchedNSManagedObjects: [NSManagedObject] = []

                    for nsFetchRequest in nsFetchRequests {
                        let fetchedResultsController = NSFetchedResultsController<NSManagedObject>(
                            fetchRequest: nsFetchRequest,
                            managedObjectContext: self.nsManagedObjectContext,
                            sectionNameKeyPath: nil,
                            cacheName: nil
                        )

                        try fetchedResultsController.performFetch()

                        fetchedNSManagedObjects.append(contentsOf: fetchedResultsController.fetchedObjects ?? [])
                    }

                    attemptToFulfill(.success(Database.ZoneQueryRequest.Result(records: fetchedNSManagedObjects.map({ Record(rawObject: $0) }))))
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

    // MARK: - Internal -

    func nsPersistentStore(for zoneID: _CoreData.Database.Zone.ID) throws -> NSPersistentStore {
        let persistentStoreCoordinator = try nsManagedObjectContext.persistentStoreCoordinator.unwrap()

        return try persistentStoreCoordinator.persistentStore(for: zoneID.fileURL).unwrap()
    }
}

// MARK: - Helpers -

fileprivate extension DatabaseRecordMergeConflict where Context == _CoreData.DatabaseRecordSpace {
    init(conflict: NSMergeConflict) {
        self.source = .init(rawObject: conflict.sourceObject)
    }
}

extension DatabaseZoneQueryRequest where Database == _CoreData.Database {
    func toNSFetchRequests(
        recordSpace: Database.RecordSpace
    ) throws -> [NSFetchRequest<NSManagedObject>] {
        guard !filters.recordTypes.isEmpty else {
            throw _CoreData.DatabaseRecordSpace.DatabaseZoneQueryRequestError.atLeastOneRecordTypeRequired
        }

        guard filters.recordTypes.count == 1 else {
            throw _CoreData.DatabaseRecordSpace.DatabaseZoneQueryRequestError.multipleRecordTypesUnsupported
        }

        var nsFetchRequests: [NSFetchRequest<NSManagedObject>] = []

        for recordType in filters.recordTypes {

            let nsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: recordType.rawValue)

            switch self.predicate {
                case .related(_, _):
                    TODO.unimplemented
                case let ._nsPredicate(predicate):
                    nsFetchRequest.predicate = predicate
                case .none:
                    nsFetchRequest.predicate = nil
            }

            nsFetchRequest.sortDescriptors = self.sortDescriptors.map({ $0.map({ $0 as NSSortDescriptor }) })

            nsFetchRequest.affectedStores = try recordSpace
                .affectedStores?
                .filter({ (self.filters.zones?.contains($0) ?? false) })
                .map({ try recordSpace.nsPersistentStore(for: $0) })

            nsFetchRequest.includesSubentities = filters.includesSubentities

            if let cursor = cursor {
                if case .offset(let offset) = cursor {
                    nsFetchRequest.fetchOffset = offset
                } else {
                    throw Never.Reason.illegal
                }
            }

            if let fetchLimit = fetchLimit {
                switch fetchLimit {
                    case .cursor(.offset(let offset)):
                        nsFetchRequest.fetchLimit = offset
                    case .none:
                        nsFetchRequest.fetchLimit = 0
                    default:
                        fatalError(reason: .unimplemented)
                }
            }

            nsFetchRequests.append(nsFetchRequest)
        }

        return nsFetchRequests
    }
}

extension _CoreData.DatabaseRecordSpace {
    enum DatabaseZoneQueryRequestError: Swift.Error {
        case atLeastOneRecordTypeRequired
        case multipleRecordTypesUnsupported
    }
}
