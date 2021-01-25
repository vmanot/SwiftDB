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
    }
    
    public var id: ID {
        .init(
            zoneName: ckRecordZone.zoneID.zoneName,
            ownerName: ckRecordZone.zoneID.ownerName
        )
    }
}
