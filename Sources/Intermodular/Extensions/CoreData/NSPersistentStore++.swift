//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

extension NSPersistentStore {
    func destroy() throws {
        let persistentStoreCoordinator = try persistentStoreCoordinator.unwrap()
        
        let url = try self.url.unwrap()

        try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: type, options: nil)
        try persistentStoreCoordinator.remove(self)

        try FileManager.default.removeItem(at: url)
    }
}
