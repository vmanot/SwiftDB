//
// Copyright (c) Vatsal Manot
//

import Swallow
import Merge

public struct AnyDatabaseRecordRelationship: DatabaseRecordRelationship {
    public typealias Record = AnyDatabaseRecord
    
    private let base: _opaque_DatabaseRecordRelationship

    init(base: _opaque_DatabaseRecordRelationship) {
        self.base = base
    }

    public func insert(_ record: Record) throws {
        try base._opaque_insert(record.base)
    }
    
    public func remove(_ record: Record) throws {
        try base._opaque_remove(record.base)
    }
    
    public func all() throws -> [Record] {
        try base._opaque_all().map({ AnyDatabaseRecord(base: $0) })
    }
}
