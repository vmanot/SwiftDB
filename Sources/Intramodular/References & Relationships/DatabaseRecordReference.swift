//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _opaque_DatabaseRecordReference: _opaque_Hashable {
    
}

/// A persistent reference to a database record.
public protocol DatabaseRecordReference {
    associatedtype RecordID: Hashable

    var recordID: RecordID { get }
}

// MARK: - Auxiliary Implementation -

public struct NoDatabaseRecordReference<RecordID: Hashable>: DatabaseRecordReference {
    public var recordID: RecordID {
        fatalError()
    }
}
