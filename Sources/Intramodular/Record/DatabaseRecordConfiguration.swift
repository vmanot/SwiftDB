//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct DatabaseRecordConfiguration<Context: DatabaseRecordSpace> {
    public let recordType: Context.Record.RecordType
    public let recordID: Context.Record.ID?
    public let zone: Context.Zone?
}
