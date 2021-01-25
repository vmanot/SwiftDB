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
    }
}
