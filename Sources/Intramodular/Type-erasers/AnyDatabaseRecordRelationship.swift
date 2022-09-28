//
// Copyright (c) Vatsal Manot
//

import Swallow
import Merge

public struct AnyDatabaseRecordRelationship: DatabaseRecordRelationship {
    public typealias Record = AnyDatabaseRecord
    
    private let base: any DatabaseRecordRelationship

    private init(base: any DatabaseRecordRelationship) {
        self.base = base
    }
    
    public init<Relationship: DatabaseRecordRelationship>(erasing relationship: Relationship) {
        assert(!(relationship is AnyDatabaseRecordRelationship))
        
        self.init(base: relationship)
    }

    public func insert(_ record: Record) throws {
        try base._opaque_insert(record)
    }
    
    public func remove(_ record: Record) throws {
        try base._opaque_remove(record)
    }
    
    public func all() throws -> [Record] {
        try base._opaque_all()
    }
}

// MARK: - Supplementary API -

extension DatabaseRecordRelationship {
    public func eraseToAnyDatabaseRelationship() -> AnyDatabaseRecordRelationship {
        assert(!(self is AnyDatabaseRecordRelationship))
        
        return .init(erasing: self)
    }
}

// MARK: - Auxiliary Implementation -

private extension DatabaseRecordRelationship {
    func _opaque_insert(_ record: AnyDatabaseRecord) throws {
        try insert(record._cast(to: Record.self))
    }
    
    func _opaque_remove(_ record: AnyDatabaseRecord) throws {
        try remove(record._cast(to: Record.self))
    }
    
    func _opaque_all() throws -> [AnyDatabaseRecord] {
        try all().map({ .init(erasing: $0) })
    }
}
