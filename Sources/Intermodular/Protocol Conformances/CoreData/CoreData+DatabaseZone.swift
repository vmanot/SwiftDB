//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public struct Zone: DatabaseZone, Identifiable, Named {
        let persistentStore: NSPersistentStore
        
        init(persistentStore: NSPersistentStore) {
            self.persistentStore = persistentStore
        }
        
        public var name: String {
            persistentStore.configurationName
        }
        
        public var id: String {
            persistentStore.identifier
        }
    }
}
