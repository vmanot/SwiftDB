//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Swallow

public protocol DatabaseRecordReference {
    associatedtype RecordContext: DatabaseRecordContext
    
    var recordID: RecordContext.RecordID { get }
}
