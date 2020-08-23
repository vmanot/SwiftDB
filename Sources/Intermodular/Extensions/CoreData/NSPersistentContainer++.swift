//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Swallow

extension NSPersistentContainer {
    public func loadPersistentStores() -> Future<Void, Error> {
        .init { attemptToFulfill in
            self.loadPersistentStores { storeDescription, error in
                if let error = error {
                    attemptToFulfill(.failure(error))
                } else {
                    attemptToFulfill(.success(()))
                }
            }
        }
    }
    
    @discardableResult
    public func performBackgroundTaskAndSave(_ closure: @escaping (NSManagedObjectContext) -> Void) -> Future<Void, Error> {
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
