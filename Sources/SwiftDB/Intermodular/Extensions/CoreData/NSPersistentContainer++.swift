//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Runtime
import Swallow
import os

extension NSPersistentContainer {
    /// Create a container with the specified name and managed object model.
    convenience init(name: String, managedObjectModel: NSManagedObjectModel?) {
        if let managedObjectModel = managedObjectModel {
            self.init(name: name, managedObjectModel: managedObjectModel)
        } else {
            self.init(name: name)
        }
    }
    
    /// Loads the persistent stores.
    func loadPersistentStores() -> AsyncStream<(description: NSPersistentStoreDescription, error: (any Error)?)> {
        let (stream, continuation) = AsyncStream<(description: NSPersistentStoreDescription, error: (any Error)?)>.makeStream()

        guard !persistentStoreDescriptions.isEmpty else {
            continuation.finish()
            return stream
        }

        let lock = OSAllocatedUnfairLock<[NSPersistentStoreDescription]>(initialState: persistentStoreDescriptions)

        self.loadPersistentStores { description, error in
            continuation.yield((description, error))

            lock.withLock { descriptions in
                descriptions.removeAll(of: description)
                if descriptions.isEmpty {
                    continuation.finish()
                }
            }
        }

        return stream
    }
    
    func persistentStoreDescription(
        for store: NSPersistentStore
    ) -> NSPersistentStoreDescription? {
        persistentStoreDescriptions.first(where: { store.url == $0.url })
    }
    
    func persistentStore(
        for description: NSPersistentStoreDescription
    ) -> NSPersistentStore? {
        persistentStoreCoordinator.persistentStores.first(where: { description.configuration == $0.configurationName && description.url == $0.url })
    }
    
    @discardableResult
    func performBackgroundTaskAndSave(
        _ closure: @escaping (NSManagedObjectContext) -> Void
    ) -> Future<Void, Error> {
        .init { attemptToFulfill in
            self.performBackgroundTask { context in
                closure(context)
                
                do {
                    attemptToFulfill(.success(try context.save()))
                } catch {
                    attemptToFulfill(.failure(error))
                }
            }
        }
    }
}
