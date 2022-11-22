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
        
        func getRecord() throws -> Record.ID? {
            try base._opaque_getRecord()
        }
        
        func setRecord(_ recordID: Record.ID?) throws {
            try base._opaque_setRecord(recordID)
        }
    }
    
    struct _ToManyRelationship: ToManyDatabaseRecordRelationship {
        typealias Record = AnyDatabaseRecord
        
        let base: any ToManyDatabaseRecordRelationship
        
        init<Relationship: ToManyDatabaseRecordRelationship>(erasing relationship: Relationship) {
            assert(!(relationship is _ToManyRelationship))
            
            self.base = relationship
        }
        
        func insert(_ recordID: Record.ID) throws {
            try base._opaque_insert(recordID)
        }
        
        func remove(_ recordID: Record.ID) throws {
            try base._opaque_remove(recordID)
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

// MARK: - Auxiliary -

private extension ToOneDatabaseRecordRelationship {
    func _opaque_getRecord() throws -> AnyDatabaseRecord.ID? {
        try getRecord().map({ AnyDatabaseRecord.ID(erasing: $0) })
    }
    
    func _opaque_setRecord(_ recordID: AnyDatabaseRecord.ID?) throws {
        try setRecord(recordID?._cast(to: Record.ID.self))
    }
}

private extension ToManyDatabaseRecordRelationship {
    func _opaque_insert(_ recordID: AnyDatabaseRecord.ID) throws {
        try insert(recordID._cast(to: Record.ID.self))
    }
    
    func _opaque_remove(_ recordID: AnyDatabaseRecord.ID) throws {
        try remove(recordID._cast(to: Record.ID.self))
    }
    
    func _opaque_all() throws -> [AnyDatabaseRecord] {
        try all().map({ .init(erasing: $0) })
    }
}
