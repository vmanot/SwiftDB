//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Swallow

public protocol _opaque_DatabaseRecordReference: _opaque_Hashable {
    
}

/// A persistent reference to a database record.
public protocol DatabaseRecordReference {
    associatedtype RecordContext: DatabaseRecordContext
    
    var recordID: RecordContext.RecordID { get }
}
