//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

extension NSPersistentStoreCoordinator {    
    func destroyAll() throws {
        for store in persistentStores {
            try store.destroy(persistentStoreCoordinator: self)
        }
    }
}
