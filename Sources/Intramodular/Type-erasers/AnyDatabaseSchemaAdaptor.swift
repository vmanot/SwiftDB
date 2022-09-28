//
// Copyright (c) Vatsal Manot
//

import Swallow
import Merge

public struct AnyDatabaseSchemaAdaptor: DatabaseSchemaAdaptor {
    public typealias Database = AnyDatabase
    
    private let base: any DatabaseSchemaAdaptor
    
    public init<Adaptor: DatabaseSchemaAdaptor>(erasing adaptor: Adaptor) {
        self.base = adaptor
    }
    
    public func recordType(
        for entity: DatabaseSchema.Entity.ID?
    ) throws -> AnyDatabaseRecord.RecordType {
        try AnyDatabaseRecord.RecordType(erasing: base.recordType(for: entity))
    }
    
    public func entity(forRecordType recordType: AnyDatabaseRecord.RecordType) throws -> DatabaseSchema.Entity.ID? {
        try base._opaque_entity(forRecordType: recordType)
    }
}

// MARK: - Auxiliary Implementation -

extension DatabaseSchemaAdaptor {
    public func _opaque_entity(
        forRecordType recordType: AnyDatabaseRecord.RecordType
    ) throws -> DatabaseSchema.Entity.ID? {
        try entity(forRecordType: recordType._cast(to: Database.RecordContext.RecordType.self))
    }
}
