//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.DatabaseRecord {
    public struct Reference: DatabaseRecordReference {
        public typealias RecordSpace = _CoreData.DatabaseRecordSpace
        
        private let nsManagedObject: NSManagedObject
        
        public var recordID: RecordSpace.Record.ID {
            .init(managedObjectID: nsManagedObject.objectID)
        }
        
        public var zoneID: RecordSpace.Zone.ID {
            _CoreData.Database.Zone(persistentStore: nsManagedObject.objectID.persistentStore!).id
        }
        
        init(managedObject: NSManagedObject) {
            self.nsManagedObject = managedObject
        }
    }
}
