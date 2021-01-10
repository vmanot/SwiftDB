//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CloudKit {
    public struct DatabaseZone {
        let base: CKRecordZone
        
        init(base: CKRecordZone) {
            self.base = base
        }
    }
}

extension _CloudKit.DatabaseZone: DatabaseZone {
    public var name: String {
        base.zoneID.zoneName
    }
    
    public var ownerName: String {
        base.zoneID.ownerName
    }
}

extension _CloudKit.DatabaseZone {
    public struct ID: Codable & Hashable {
        let zoneName: String
        let ownerName: String
    }
    
    public var id: ID {
        .init(zoneName: base.zoneID.zoneName, ownerName: base.zoneID.ownerName)
    }
}
