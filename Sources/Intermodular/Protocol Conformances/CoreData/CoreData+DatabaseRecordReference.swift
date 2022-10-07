//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.DatabaseRecord {
    public struct Reference: DatabaseRecordReference {
        public typealias RecordContext = _CoreData.DatabaseRecordContext
        
        private let nsManagedObject: NSManagedObject
        
        public var recordID: RecordContext.Record.ID {
            .init(managedObjectID: nsManagedObject.objectID)
        }
        
        public var zoneID: RecordContext.Zone.ID {
            _CoreData.Database.Zone(persistentStore: nsManagedObject.objectID.persistentStore!).id
        }
        
        init(managedObject: NSManagedObject) {
            self.nsManagedObject = managedObject
        }
    }
}
