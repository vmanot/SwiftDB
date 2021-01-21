//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct DatabaseRecordConfiguration<Context: DatabaseRecordContext> {
    public let recordType: Context.RecordType
    public let recordID: Context.RecordID?
    public let zone: Context.Zone?
}
