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
        for entity: _Schema.Entity.ID?
    ) throws -> AnyDatabaseRecord.RecordType {
        try AnyDatabaseRecord.RecordType(erasing: base.recordType(for: entity))
    }
    
    public func entity(
        forRecordType recordType: AnyDatabaseRecord.RecordType
    ) throws -> _Schema.Entity.ID? {
        try base._opaque_entity(forRecordType: recordType)
    }
}

// MARK: - Auxiliary -

extension DatabaseSchemaAdaptor {
    public func _opaque_entity(
        forRecordType recordType: AnyDatabaseRecord.RecordType
    ) throws -> _Schema.Entity.ID? {
        try entity(forRecordType: recordType._cast(to: Database.RecordSpace.Record.RecordType.self))
    }
}
