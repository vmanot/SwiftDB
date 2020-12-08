//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CoreData {
    public struct Zone: DatabaseZone {
        let base: NSPersistentStore
        
        init(base: NSPersistentStore) {
            self.base = base
        }
        
        public var name: String {
            base.configurationName
        }
        
        public var id: String {
            base.identifier
        }
    }
}
