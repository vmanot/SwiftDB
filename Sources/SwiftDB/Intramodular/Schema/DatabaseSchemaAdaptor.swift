//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol DatabaseSchemaAdaptor {
    associatedtype Database: SwiftDB.Database

    /// The corresponding record type for a given entity.
    func recordType(for entity: _Schema.Entity.ID?) throws -> Database.Record.RecordType

    /// The corresponding entity ID for a given record type.
    func entity(forRecordType recordType: Database.Record.RecordType) throws -> _Schema.Entity.ID?
}
