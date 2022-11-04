//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow
import Combine
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
            do {
                try queryRequest.toNSFetchRequests(recordSpace: recordSpace).map {
                    NSFetchedResultsPublisher(
                        fetchRequest: $0,
                        managedObjectContext: recordSpace.nsManagedObjectContext
                    )
                }
                .reduce(AnyPublisher<[Database.Record], Error>.just([])) { partialResult, publisher in
                    // FIXME: This doesn't account for `queryRequest`'s sort descriptors.
                    partialResult
                        .zip(publisher)
                        .map({ $0.0.appending(contentsOf: $0.1.map({ Database.Record(rawObject: $0) })) })
                        .eraseToAnyPublisher()
                }
                .receive(subscriber: subscriber)
            } catch {
                subscriber.receive(completion: .failure(error))
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
        private var subject = CurrentValueSubject<[NSManagedObject], Never>([])
        
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
                .sink { [weak self] in
                    guard let self = self, let subscriber = self.subscriber else {
                        assertionFailure()
                        return
                    }
                    _ = subscriber.receive($0)
                }
        }
        
        func request(_ demand: Subscribers.Demand) {
            // When a demand is sent this means we should re-send the latest buffer, since subscribing can happen later after the initialization.
            subject.send(subject.value)
        }
        
        func cancel() {
            subjectCancellable?.cancel()
            subjectCancellable = nil
            
            // Clean up any strong references
            fetchedResultsController = nil
            managedObjectContext = nil
            subscriber = nil
        }
        
        private func setUpFetchedResultsController() {
            guard let managedObjectContext = managedObjectContext else {
                preconditionFailure("The managed object context should only be nil after cancelling the subscription.")
            }
            
            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            fetchedResultsController.delegate = self
            
            self.fetchedResultsController = fetchedResultsController
            
            do {
                try fetchedResultsController.performFetch()
                let objects = fetchedResultsController.fetchedObjects
                
                // Push initial set of objects to the subject
                subject.send(objects ?? [])
                
            } catch {
                
                // Surface unexpected errors in debug builds
                assertionFailure(error.localizedDescription)
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
