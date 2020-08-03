import Foundation
import Combine
import CoreData

/// Publisher that publishes up-to-date lists of entities of a specified entity type in a specified managed object context.
public struct FetchedResultsPublisher<Entity: NSManagedObject>: Publisher {
    public typealias Output = [Entity]
    public typealias Failure = Error

    /// The managed object context to monitor
    private let managedObjectContext: NSManagedObjectContext

    /// Creates a publisher that retains the managed object context passed to it.
    /// - Parameter managedObjectContext: the managed object context to monitor
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscriber.receive(subscription: FetchedResultsSubscription(
            subscriber: subscriber,
            entity: Entity.self,
            managedObjectContext: managedObjectContext
        ))
    }
}

final class FetchedResultsSubscription<SubscriberType: Subscriber, Entity: NSManagedObject>:
    NSObject, Subscription, NSFetchedResultsControllerDelegate where SubscriberType.Input == [Entity] {

    /// Cancellable for the internal subscription that pushes updates entity lists to the subscribers.
    private var subjectCancellable: AnyCancellable?
    private var subscriber: SubscriberType?

    /// The managed object context to be monitored with an NSFetchedResultsController
    private var managedObjectContext: NSManagedObjectContext?

    /// The fetched results controller responsible to manage updates for a given entity type
    private var fetchedResultsController: NSFetchedResultsController<Entity>?

    /// The entity type that is monitored, defines the Output type.
    private var entity: Entity.Type

    /// Internal buffer of the latest set of entities of the fetched results controller
    private var subject = CurrentValueSubject<[Entity], Never>([])

    func request(_ demand: Subscribers.Demand) {

        // When a demand is sent this means we should re-send the latest buffer, since
        // subscribing can happen later after the initialization.
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

    init(subscriber: SubscriberType, entity: Entity.Type, managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.entity = entity
        self.subscriber = subscriber

        super.init()

        createFetchedResultsController()

        subjectCancellable = subject
            .sink { [weak self] in
                guard let self = self, let subscriber = self.subscriber else {
                    assertionFailure("Subscription deallocated early.")
                    return
                }
                _ = subscriber.receive($0)
            }
    }

    /// Sets up the fetched results controller with a fetch request and the specified managed object context.
    private func createFetchedResultsController() {
        guard let managedObjectContext = managedObjectContext else {
            preconditionFailure("The managed object context should only be nil after cancelling the subscription.")
        }

        guard let request = entity.fetchRequest() as? NSFetchRequest<Entity> else {
            preconditionFailure("We should always be able to get the correctly typed fetch request.")
        }

        // Since we do not know anything about the entity, we are not able to add sorting to the fetch.
        // In future updates one could add protocol requirements to sort by common properties of entities.
        request.sortDescriptors = []

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
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

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Whenever the controller receives object changes, we push them to the subject which in turn
        // will send the objects to the receiver(s).
        if let objects = controller.fetchedObjects as? [Entity] {
            subject.send(objects)
        }
    }
}
