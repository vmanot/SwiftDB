//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

extension NSPersistentStore {
    func destroy(
        persistentStoreCoordinator coordinator: NSPersistentStoreCoordinator
    ) throws {
        let url = try self.url.unwrap()
        
        try coordinator.replacePersistentStore(
            at: url,
            destinationOptions: nil,
            withPersistentStoreFrom: url,
            sourceOptions: nil,
            ofType: type
        )
        
        try coordinator.destroyPersistentStore(
            at: url,
            ofType: type,
            options: nil
        )
        
        if coordinator.persistentStores.contains(self) {
            try coordinator.remove(self)
        }
        
        let fileManager = FileManager.default
        let fileDeleteCoordinator = NSFileCoordinator(filePresenter: nil)
        
        fileDeleteCoordinator.coordinate(
            writingItemAt: url.deletingLastPathComponent(),
            options: .forDeleting,
            error: nil,
            byAccessor: { url in
                if fileManager.fileExists(at: url) {
                    try? fileManager.removeItem(at: url)
                }
                
                let ckAssetFilesURL = url.deletingLastPathComponent().appendingPathComponent("ckAssetFiles")
                
                if fileManager.fileExists(at: ckAssetFilesURL) {
                    try? fileManager.removeItem(at: ckAssetFilesURL)
                }
            }
        )
    }
}
