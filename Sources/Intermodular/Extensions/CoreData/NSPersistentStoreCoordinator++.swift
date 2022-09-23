//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

struct NSPersistentStoreMetadata {
    let persistenceFrameworkVersion: Int
    let storeUUID: UUID
    let storeModelVersionHashesVersion: Int
    var storeModelVersionHashesDigest: String
    let storeModelVersionHashes: [String: Data]
    let autoVacuumLevel: String
    let storeType: String

    init(from metadata: [String: Any]) throws {
        persistenceFrameworkVersion = try cast(metadata["NSPersistenceFrameworkVersion"])
        storeUUID = try UUID(uuidString: try cast(metadata["NSStoreUUID"], to: String.self)).unwrap()
        storeModelVersionHashesVersion = try cast(metadata["NSStoreModelVersionHashesVersion"])
        // = try cast(metadata["NSStoreModelVersionIdentifiers"])
        storeModelVersionHashesDigest = try cast(metadata["NSStoreModelVersionHashesDigest"])
        storeModelVersionHashes = try cast(metadata["NSStoreModelVersionHashes"])
        autoVacuumLevel = try cast(metadata["_NSAutoVacuumLevel"])
        storeType = try cast(metadata["NSStoreType"])
    }
}

extension NSPersistentStoreCoordinator {
    /// Check whether a store at the given location is compatible with a given object model.
    static func isStore(
        ofType storeType: String,
        at storeURL: URL,
        withConfigurationName configurationName: String?,
        compatibleWithModel model: NSManagedObjectModel
    ) throws -> Bool {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: storeURL, options: nil)
        
        return model.isConfiguration(withName: configurationName, compatibleWithStoreMetadata: metadata)
    }

    func destroyAll() throws {
        for store in persistentStores {
            try store.destroy(persistentStoreCoordinator: self)
        }
    }
}
