//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public func performMigrationCheck() async throws -> DatabaseMigrationCheck<_CoreData.Database> {
        let persistentStoreCoordinator = nsPersistentContainer.persistentStoreCoordinator
        let availableZones = try await fetchAllAvailableZones()
        
        var zonesToMigrate: Set<_CoreData.Database.ID> = []
        
        for zone in availableZones {
            let metadata = persistentStoreCoordinator.metadata(for: zone.persistentStore)
            
            let isCompatible = persistentStoreCoordinator.managedObjectModel.isConfiguration(
                withName: zone.persistentStore.configurationName,
                compatibleWithStoreMetadata: metadata
            )
            
            if !isCompatible {
                zonesToMigrate.insert(zone.id)
            }
        }
        
        return DatabaseMigrationCheck(zonesToMigrate: zonesToMigrate)
    }
}
