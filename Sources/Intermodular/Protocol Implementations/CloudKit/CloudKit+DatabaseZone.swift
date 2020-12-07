//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CloudKit {
    struct Zone: DatabaseZone {
        struct ID: Codable & Hashable {
            let zoneName: String
            let ownerName: String
        }
        
        let base: CKRecordZone
        
        var name: String {
            base.zoneID.zoneName
        }

        var ownerName: String {
            base.zoneID.ownerName
        }

        var id: ID {
            .init(zoneName: base.zoneID.zoneName, ownerName: base.zoneID.ownerName)
        }
    }
}
