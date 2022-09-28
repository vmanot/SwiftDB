//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol DatabaseSchemaAdaptor {
    associatedtype Database: SwiftDB.Database
    
    /// The corresponding record type for a given entity.
    func recordType(for entity: DatabaseSchema.Entity.ID?) throws -> Database.RecordContext.RecordType
    
    /// The corresponding entity ID for a given record type.
    func entity(forRecordType recordType: Database.RecordContext.RecordType) throws -> DatabaseSchema.Entity.ID?
}
