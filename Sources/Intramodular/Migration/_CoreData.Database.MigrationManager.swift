//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

extension _CoreData.Database {
    final class MigrationManager: NSMigrationManager, ProgressReporting {
        let progress: Progress
        
        override func didChangeValue(forKey key: String) {
            super.didChangeValue(forKey: key)
            
            if key == #keyPath(NSMigrationManager.migrationProgress) {
                self.progress.completedUnitCount = max(
                    progress.completedUnitCount,
                    Int64(Float(progress.totalUnitCount) * self.migrationProgress)
                )
            }
        }
        
        
        init(
            sourceModel: NSManagedObjectModel,
            destinationModel: NSManagedObjectModel, p
            progress: Progress
        ) {
            self.progress = progress
            
            super.init(sourceModel: sourceModel, destinationModel: destinationModel)
        }
    }
}
