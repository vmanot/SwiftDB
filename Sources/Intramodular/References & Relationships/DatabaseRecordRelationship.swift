//
// Copyright (c) Vatsal Manot
//

import Swallow

public enum DatabaseRecordRelationshipType {
    case toOne
    case toMany
    case orderedToMany
}

/// An encapsulation of a relationship from one database record to another/set of other records.
public protocol DatabaseRecordRelationship<Record> {
    associatedtype Record: DatabaseRecord
    
    func toOneRelationship() throws -> any ToOneDatabaseRecordRelationship<Record>
    func toManyRelationship() throws -> any ToManyDatabaseRecordRelationship<Record>
}

public protocol ToOneDatabaseRecordRelationship<Record> {
    associatedtype Record: DatabaseRecord
    
    func getRecord() throws -> Record?
    func setRecord(_ record: Record?) throws
}

/// An encapsulation of a relationship from one database record to another record OR a set of records.
public protocol ToManyDatabaseRecordRelationship<Record> {
    associatedtype Record: DatabaseRecord
    
    func insert(_ record: Record) throws
    func remove(_ record: Record) throws
    
    func all() throws -> [Record]
}

// MARK: - Auxiliary Implementation -

public struct NoDatabaseRecordRelationship<Record: DatabaseRecord>: DatabaseRecordRelationship {
    public func toOneRelationship() throws -> any ToOneDatabaseRecordRelationship<Record> {
        throw Never.Reason.unavailable
    }
    
    public func toManyRelationship() throws -> any ToManyDatabaseRecordRelationship<Record> {
        throw Never.Reason.unavailable
    }
}

extension DatabaseRecord where Relationship == NoDatabaseRecordRelationship<Self> {
    public func relationship(for key: CodingKey) -> Relationship {
        .init()
    }
}
