//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit {
    public struct DatabaseZone {
        let ckRecordZone: CKRecordZone
        
        init(recordZone: CKRecordZone) {
            self.ckRecordZone = recordZone
        }
    }
}

extension _CloudKit.DatabaseZone: DatabaseZone {
    public var name: String {
        ckRecordZone.zoneID.zoneName
    }
    
    public var ownerName: String {
        ckRecordZone.zoneID.ownerName
    }
}

extension _CloudKit.DatabaseZone {
    public struct ID: Codable & Hashable {
        let zoneName: String?
        let ownerName: String?
        
        var ckRecordZoneID: CKRecordZone.ID {
            .init(
                zoneName: zoneName ?? CKRecordZone.ID.defaultZoneName,
                ownerName: ownerName ?? CKCurrentUserDefaultName
            )
        }
        
        init(zoneName: String?, ownerName: String?) {
            self.zoneName = zoneName
            self.ownerName = ownerName
        }
        
        init(zoneID: CKRecordZone.ID) {
            self.zoneName = zoneID.zoneName
            self.ownerName = zoneID.ownerName
        }
    }
    
    public var id: ID {
        .init(
            zoneName: ckRecordZone.zoneID.zoneName,
            ownerName: ckRecordZone.zoneID.ownerName
        )
    }
}
