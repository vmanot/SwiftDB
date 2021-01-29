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
        
        public var recordID: RecordContext.RecordID {
            .init(managedObjectID: nsManagedObject.objectID)
        }
        
        public var zoneID: RecordContext.Zone.ID {
            nsManagedObject.objectID.persistentStore!.identifier
        }
        
        init(managedObject: NSManagedObject) {
            self.nsManagedObject = managedObject
        }
    }
}
