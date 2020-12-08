//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CloudKit {
    public struct Zone: DatabaseZone {
        let base: CKRecordZone
        
        init(base: CKRecordZone) {
            self.base = base
        }
    }
}

extension _CloudKit.Zone {
    public struct ID: Codable & Hashable {
        let zoneName: String
        let ownerName: String
    }
    
    public var name: String {
        base.zoneID.zoneName
    }
    
    public var ownerName: String {
        base.zoneID.ownerName
    }
    
    public var id: ID {
        .init(zoneName: base.zoneID.zoneName, ownerName: base.zoneID.ownerName)
    }
}
