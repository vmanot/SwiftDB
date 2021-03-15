//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Swallow

/// A persistent reference to a database record.
public protocol DatabaseRecordReference {
    associatedtype RecordContext: DatabaseRecordContext
    
    var recordID: RecordContext.RecordID { get }
}
