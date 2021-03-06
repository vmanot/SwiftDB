//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit.DatabaseRecord {
    public struct Reference: Codable, DatabaseRecordReference {
        public typealias RecordContext = _CloudKit.DatabaseRecordContext
        
        public let recordID: ID
        public let zoneID: RecordContext.Zone.ID
        
        public var ckReference: CKRecord.Reference {
            .init(
                recordID: .init(recordName: recordID.rawValue, zoneID: zoneID.ckRecordZoneID),
                action: .none
            )
        }
        
        public init(reference: CKRecord.Reference) {
            self.recordID = .init(recordID: reference.recordID)
            self.zoneID = .init(zoneID: reference.recordID.zoneID)
        }
    }
}
