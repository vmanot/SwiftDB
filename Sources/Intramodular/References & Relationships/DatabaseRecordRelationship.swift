//
// Copyright (c) Vatsal Manot
//

import Swallow

/// An encapsulation of a relationship from one database record to another record OR a set of records.
public protocol DatabaseRecordRelationship {
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
