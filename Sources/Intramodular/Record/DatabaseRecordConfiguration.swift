//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct DatabaseRecordConfiguration<Database: SwiftDB.Database> {
    public let recordType: Database.Record.RecordType?
    public let recordID: Database.Record.ID?
    public let zone: Database.Zone?
}
