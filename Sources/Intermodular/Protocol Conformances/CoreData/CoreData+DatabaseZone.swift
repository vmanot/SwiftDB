//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public struct Zone: DatabaseZone, Identifiable, Named {
        public enum ID: Codable, Hashable {
            case fileURL(url: URL)
            case runtimeIdentifier(identifier: String)
        }
        
        let persistentStore: NSPersistentStore
       
        public let id: ID
        
        init(persistentStore: NSPersistentStore) {
            self.persistentStore = persistentStore
            self.id = .runtimeIdentifier(identifier: persistentStore.identifier)
        }
        
        public var name: String {
            persistentStore.configurationName
        }
    }
}
