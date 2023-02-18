//
// Copyright (c) Vatsal Manot
//

import API
import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public final class QuerySubscription: DatabaseQuerySubscription {
        public typealias Database = _CoreData.Database
        public typealias Output = [Database.Record]
        public typealias Failure = Swift.Error
        
        private let recordSpace: Database.RecordSpace
        private let queryRequest: Database.ZoneQueryRequest
        
        public var objectWillChange: ObservableObjectPublisher {
            recordSpace.objectWillChange
        }
        
        public init(
            recordSpace: Database.RecordSpace,
            queryRequest: Database.ZoneQueryRequest
        ) throws {
            self.recordSpace = recordSpace
            self.queryRequest = queryRequest
        }
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {
            let managedObjectContext = recordSpace.nsManagedObjectContext
            
            if let recordID = queryRequest._decomposeToSingleRecordIDIfPossible() {
                NSManagedObjectContext.ChangesPublisher(managedObjectContext: managedObjectContext)
                    .compactMap { events in
                        events.first(where: { .init(managedObjectID: $0.managedObject().objectID) == recordID })
                    }
                    .map { event in
                        switch event {
                            case let .updated(object):
                                return [object]
                            case let .inserted(object):
                                return [object]
                            case let .refreshed(object):
                                return [object]
                            case .deleted:
                                return []
                        }
                    }
                    .tryMap({ $0.map(_CoreData.DatabaseRecord.init(rawObject:)) })
                    .receive(subscriber: subscriber)
            } else {
                do {
                    guard queryRequest.filters.recordIDs == nil else {
                        TODO.unimplemented
                    }
                    
                    // FIXME: This doesn't account for `queryRequest`'s sort descriptors.
                    let publisher = try queryRequest.toNSFetchRequests(recordSpace: recordSpace)
                        .map { fetchRequest -> AnyPublisher<[Database.Record], Error> in
                            NSFetchedResultsPublisher(
                                fetchRequest: fetchRequest,
                                managedObjectContext: recordSpace.nsManagedObjectContext
                            )
                            .map({ $0.map(Database.Record.init(rawObject:)) })
                            .eraseError()
                            .eraseToAnyPublisher()
                        }
                        .reduce { (partialResult, publisher) in
                            partialResult
                                .combineLatest(publisher)
                                .map({ $0.0.appending(contentsOf: $0.1) })
                                .eraseToAnyPublisher()
                        }
                    
                    if let publisher {
                        publisher.receive(subscriber: subscriber)
                    } else {
                        assertionFailure()
                        
                        subscriber.receive(completion: .failure(Never.Reason.unavailable))
                    }
                } catch {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }
    }
}

struct NSFetchedResultsPublisher: Publisher {
    public typealias Output = [NSManagedObject]
    public typealias Failure = Error
    
    private let managedObjectContext: NSManagedObjectContext
    private let fetchRequest: NSFetchRequest<NSManagedObject>
    
    public init(
        fetchRequest: NSFetchRequest<NSManagedObject>,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.fetchRequest = fetchRequest
        self.managedObjectContext = managedObjectContext
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        subscriber.receive(
            subscription: Subscription(
                subscriber: subscriber,
                managedObjectContext: managedObjectContext,
                fetchRequest: fetchRequest
            )
        )
    }
}

extension NSFetchedResultsPublisher {
    private final class Subscription<
        SubscriberType: Subscriber
    >: NSObject, Combine.Subscription, NSFetchedResultsControllerDelegate where SubscriberType.Input == [NSManagedObject] {
        private var subjectCancellable: AnyCancellable?
        private var subscriber: SubscriberType?
        private var managedObjectContext: NSManagedObjectContext?
        private var fetchRequest: NSFetchRequest<NSManagedObject>
        
        private var fetchedResultsController: NSFetchedResultsController<NSManagedObject>?
        
        /// Internal buffer of the latest set of entities of the fetched results controller
        private var subject = CurrentValueSubject<[NSManagedObject]?, Never>(nil)
        
        init(
            subscriber: SubscriberType,
            managedObjectContext: NSManagedObjectContext,
            fetchRequest: NSFetchRequest<NSManagedObject>
        ) {
            self.managedObjectContext = managedObjectContext
            self.fetchRequest = fetchRequest
            self.subscriber = subscriber
            
            super.init()
            
            setUpFetchedResultsController()
            
            subjectCancellable = subject
                .compactMap({ $0 })
                .sink { [weak self] value in
                    guard let self = self, let subscriber = self.subscriber else {
                        assertionFailure()
                        
                        return
                    }
                    
                    managedObjectContext.perform {
                        withExtendedLifetime(subscriber) {
                            _ = subscriber.receive(value)
                        }
                    }
                }
        }
        
        func request(_ demand: Subscribers.Demand) {
            if let value = subject.value {
                subject.send(value)
            }
        }
        
        func cancel() {
            subjectCancellable?.cancel()
            subjectCancellable = nil
            
            fetchedResultsController = nil
            managedObjectContext = nil
            subscriber = nil
        }
        
        private func setUpFetchedResultsController() {
            guard let managedObjectContext = managedObjectContext else {
                preconditionFailure("The managed object context should only be nil after cancelling the subscription.")
            }
            
            managedObjectContext.perform {
                let fetchedResultsController = NSFetchedResultsController(
                    fetchRequest: self.fetchRequest,
                    managedObjectContext: managedObjectContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil
                )
                
                fetchedResultsController.delegate = self
                
                self.fetchedResultsController = fetchedResultsController
                
                do {
                    try fetchedResultsController.performFetch()
                    let fetchedObjects = fetchedResultsController.fetchedObjects
                    
                    guard let fetchedObjects = fetchedObjects else {
                        return
                    }
                    
                    self.subject.send(fetchedObjects)
                } catch {
                    assertionFailure(error)
                }
            }
        }
        
        // MARK: - NSFetchedResultsControllerDelegate
        
        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            if let objects = controller.fetchedObjects as? [NSManagedObject] {
                subject.send(objects)
            }
        }
    }
}

// MARK: - Helpers

extension DatabaseZoneQueryRequest {
    fileprivate func _decomposeToSingleRecordIDIfPossible() -> Database.Record.ID? {
        guard filters.zones == nil else {
            return nil
        }
        
        guard let recordIDs = filters.recordIDs, let recordID = recordIDs.first, recordIDs.count == 1 else {
            return nil
        }
        
        guard predicate == nil else {
            return nil
        }
        
        guard (sortDescriptors ?? []) == [] else {
            return nil
        }
        
        guard cursor == nil else {
            return nil
        }
        
        guard fetchLimit == FetchLimit.max(1) else {
            return nil
        }
        
        return recordID
    }
}
