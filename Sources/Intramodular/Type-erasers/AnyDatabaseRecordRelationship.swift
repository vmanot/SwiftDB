//
// Copyright (c) Vatsal Manot
//

import Swallow
import Merge

public struct AnyDatabaseRecordRelationship: DatabaseRecordRelationship {
    public typealias Record = AnyDatabaseRecord
    
    let base: any DatabaseRecordRelationship
    
    public init<Relationship: DatabaseRecordRelationship>(erasing relationship: Relationship) {
        assert(!(relationship is AnyDatabaseRecordRelationship))
        
        self.base = relationship
    }
    
    public func toOneRelationship() throws -> any ToOneDatabaseRecordRelationship<Record> {
        fatalError()
    }
    
    public func toManyRelationship() throws -> any ToManyDatabaseRecordRelationship<Record> {
        try base.toManyRelationship().eraseToAnyToManyDatabaseRelationship()
    }
}

public struct AnyToManyDatabaseRecordRelationship: ToManyDatabaseRecordRelationship {
    public typealias Record = AnyDatabaseRecord
    
    private let base: any ToManyDatabaseRecordRelationship
    
    private init(base: any ToManyDatabaseRecordRelationship) {
        self.base = base
    }
    
    public init<Relationship: ToManyDatabaseRecordRelationship>(erasing relationship: Relationship) {
        assert(!(relationship is AnyToManyDatabaseRecordRelationship))
        
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

extension ToManyDatabaseRecordRelationship {
    public func eraseToAnyToManyDatabaseRelationship() -> AnyToManyDatabaseRecordRelationship {
        assert(!(self is AnyToManyDatabaseRecordRelationship))
        
        return .init(erasing: self)
    }
}

// MARK: - Auxiliary Implementation -

private extension ToManyDatabaseRecordRelationship {
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
