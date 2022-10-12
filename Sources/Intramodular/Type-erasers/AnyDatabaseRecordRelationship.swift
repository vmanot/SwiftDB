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
        _ToOneRelationship(erasing: try base.toOneRelationship())
    }
    
    public func toManyRelationship() throws -> any ToManyDatabaseRecordRelationship<Record> {
        _ToManyRelationship(erasing: try base.toManyRelationship())
    }
}

extension AnyDatabaseRecordRelationship {
    struct _ToOneRelationship: ToOneDatabaseRecordRelationship {
        typealias Record = AnyDatabaseRecord
        
        let base: any ToOneDatabaseRecordRelationship
        
        init<Relationship: ToOneDatabaseRecordRelationship>(erasing relationship: Relationship) {
            assert(!(relationship is _ToOneRelationship))
            
            self.base = relationship
        }
        
        func getRecord() throws -> Record? {
            try base._opaque_getRecord()
        }
        
        func setRecord(_ record: Record?) throws {
            try base._opaque_setRecord(record)
        }
    }
    
    struct _ToManyRelationship: ToManyDatabaseRecordRelationship {
        typealias Record = AnyDatabaseRecord
        
        let base: any ToManyDatabaseRecordRelationship
        
        init<Relationship: ToManyDatabaseRecordRelationship>(erasing relationship: Relationship) {
            assert(!(relationship is _ToManyRelationship))
            
            self.base = relationship
        }
        
        func insert(_ record: Record) throws {
            try base._opaque_insert(record)
        }
        
        func remove(_ record: Record) throws {
            try base._opaque_remove(record)
        }
        
        func all() throws -> [Record] {
            try base._opaque_all()
        }
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

private extension ToOneDatabaseRecordRelationship {
    func _opaque_getRecord() throws -> AnyDatabaseRecord? {
        try getRecord().map({ AnyDatabaseRecord(erasing: $0) })
    }
    
    func _opaque_setRecord(_ record: AnyDatabaseRecord?) throws {
        try setRecord(record?._cast(to: Record.self))
    }
}

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
