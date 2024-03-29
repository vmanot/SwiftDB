//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Runtime
import Swallow

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
    func loadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.loadPersistentStores { storeDescription, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
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
