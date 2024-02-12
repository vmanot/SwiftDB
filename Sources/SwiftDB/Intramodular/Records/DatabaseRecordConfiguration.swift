//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct DatabaseRecordConfiguration<Database: SwiftDB.Database> {
    public let recordType: Database.Record.RecordType?
    public let recordID: Database.Record.ID?
    public let zone: Database.Zone?
    
    public init(
        recordType: Database.Record.RecordType?,
        recordID: Database.Record.ID?,
        zone: Database.Zone?
    ) {
        self.recordType = recordType
        self.recordID = recordID
        self.zone = zone
    }
}

extension DatabaseRecordConfiguration where Database == AnyDatabase {
    func _cast<T: SwiftDB.Database>(
        to other: DatabaseRecordConfiguration<T>.Type
    ) throws -> DatabaseRecordConfiguration<T> {
        .init(
            recordType: try recordType?._cast(to: T.Record.RecordType.self),
            recordID: try recordID.map({ try $0._cast(to: T.Record.ID.self) }),
            zone: try zone.map({ try cast($0.base, to: T.Zone.self) })
        )
    }
}
