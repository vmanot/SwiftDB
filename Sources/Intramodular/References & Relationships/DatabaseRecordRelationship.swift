//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _opaque_DatabaseRecordRelationship {
    func _opaque_insert(_ record: _opaque_DatabaseRecord) throws
    func _opaque_remove(_ record: _opaque_DatabaseRecord) throws
    func _opaque_all() throws -> [_opaque_DatabaseRecord]
}

extension _opaque_DatabaseRecordRelationship where Self: DatabaseRecordRelationship{
    public func _opaque_insert(_ record: _opaque_DatabaseRecord) throws {
        try insert(cast(record, to: Record.self))
    }
    
    public func _opaque_remove(_ record: _opaque_DatabaseRecord) throws {
        try remove(cast(record, to: Record.self))
    }
    
    public func _opaque_all() throws -> [_opaque_DatabaseRecord] {
        try all() as [_opaque_DatabaseRecord]
    }
}

/// An encapsulation of a relationship from one database record to another record OR a set of records.
public protocol DatabaseRecordRelationship: _opaque_DatabaseRecordRelationship {
    associatedtype Record: DatabaseRecord
    
    func insert(_ record: Record) throws
    func remove(_ record: Record) throws

    func all() throws -> [Record]
}

// MARK: - Auxiliary Implementation -

public struct NoDatabaseRecordRelationship<Record: DatabaseRecord>: DatabaseRecordRelationship {
    public func insert(_ record: Record) throws  {
        throw Never.Reason.unimplemented
    }
    
    public func remove(_ record: Record) throws {
        throw Never.Reason.unimplemented
    }
    
    public func all() throws -> [Record] {
        throw Never.Reason.unimplemented
    }
}

extension DatabaseRecord where Relationship == NoDatabaseRecordRelationship<Self> {
    public func relationship(for key: CodingKey) -> Relationship {
        .init()
    }
}
