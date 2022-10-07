//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct AnyDatabaseRecordReference: DatabaseRecordReference {
    public typealias RecordID = AnyDatabaseRecord.ID
    
    private let base: any DatabaseRecordReference
    
    public var recordID: RecordID {
        AnyDatabaseRecord.ID(base: base.recordID.eraseToAnyHashable())
    }
    
    init(base: any DatabaseRecordReference) {
        self.base = base
    }
}
