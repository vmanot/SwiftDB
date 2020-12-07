//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CoreData {
    struct Zone: DatabaseZone {
        let base: NSPersistentStore
        
        var name: String {
            base.configurationName
        }
        
        var id: String {
            base.identifier
        }
    }
}
