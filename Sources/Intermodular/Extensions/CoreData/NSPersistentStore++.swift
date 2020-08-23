//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

extension NSPersistentStore {
    public func destroy() throws {
        guard let persistentStoreCoordinator = persistentStoreCoordinator else {
            return assertionFailure()
        }
        
        let url = try self.url.unwrap()
        
        try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: type, options: nil)
        
        try FileManager.default.removeItem(at: url)
    }
}
