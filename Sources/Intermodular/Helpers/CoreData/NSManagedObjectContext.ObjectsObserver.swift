//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Combine
import CoreData
import Swift

extension NSManagedObjectContext {
    public class ObjectsObserver {
        private let eventsPublisher = PassthroughSubject<[Event], Never>()

        private let managedObjectContext: NSManagedObjectContext

        private weak var persistentStoreCoordinator: NSPersistentStoreCoordinator?

        private var notificationObserver: NSObjectProtocol?

        public init(managedObjectContext: NSManagedObjectContext) {
            self.managedObjectContext = managedObjectContext
            self.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator

            notificationObserver = NotificationCenter.default.addObserver(
                forName: NSManagedObjectContext.didChangeObjectsNotification,
                object: managedObjectContext,
                queue: nil
            ) { [weak self] notification in
                self?.handleContextObjectDidChangeNotification(notification: notification)
            }
        }

        private func handleContextObjectDidChangeNotification(
            notification: Notification
        ) {
            guard let incomingContext = notification.object as? NSManagedObjectContext,
                  let persistentStoreCoordinator = persistentStoreCoordinator,
                  let incomingPersistentStoreCoordinator = incomingContext.persistentStoreCoordinator,
                  persistentStoreCoordinator == incomingPersistentStoreCoordinator
            else {
                return
            }

            let insertedObjectsSet = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            let updatedObjectsSet = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            let deletedObjectsSet = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            let refreshedObjectsSet = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()

            var events: [Event] = []

            events += insertedObjectsSet.map({ Event.inserted($0) })
            events += updatedObjectsSet.map({ Event.updated($0) })
            events += deletedObjectsSet.map({ Event.deleted($0) })
            events += refreshedObjectsSet.map({ Event.refreshed($0) })

            eventsPublisher.send(events)
        }

        deinit {
            notificationObserver.map(NotificationCenter.default.removeObserver)
        }
    }
}

// MARK: - Conformances -

extension NSManagedObjectContext.ObjectsObserver: Publisher {
    public typealias Output = [Event]
    public typealias Failure = Never

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Never {
        eventsPublisher.receive(subscriber: subscriber)
    }
}

// MARK: - Auxiliary -

extension NSManagedObjectContext.ObjectsObserver {
    public struct ObjectEventTypes: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let inserted = Self(rawValue: 1 << 0)
        public static let updated = Self(rawValue: 1 << 1)
        public static let deleted = Self(rawValue: 1 << 2)
        public static let refreshed = Self(rawValue: 1 << 3)

        public static let all: Self  = [.inserted, .updated, .deleted, .refreshed]
    }

    public enum Event {
        case updated(NSManagedObject)
        case refreshed(NSManagedObject)
        case inserted(NSManagedObject)
        case deleted(NSManagedObject)

        public func managedObject() -> NSManagedObject {
            switch self {
                case let .updated(value):
                    return value
                case let .inserted(value):
                    return value
                case let .refreshed(value):
                    return value
                case let .deleted(value):
                    return value
            }
        }
    }
}
