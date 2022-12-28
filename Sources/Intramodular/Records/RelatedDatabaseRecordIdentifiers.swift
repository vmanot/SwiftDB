//
// Copyright (c) Vatsal Manot
//

import Compute
import Swallow

public enum DatabaseRecordRelationshipType {
    case toOne
    case toUnorderedMany
    case toOrderedMany
}

public enum RelatedDatabaseRecordIdentifiers<Database: SwiftDB.Database> {
    public enum Error: _SwiftDB_Error {
        case insertIllegal
    }
    
    case toOne(Database.Record.ID?)
    case toUnorderedMany(Set<Database.Record.ID>)
    case toOrderedMany(Array<Database.Record.ID>)
}

// MARK: - Extensions -

extension RelatedDatabaseRecordIdentifiers {
    public var relationshipType: DatabaseRecordRelationshipType {
        switch self {
            case .toOne:
                return .toOne
            case .toUnorderedMany:
                return .toUnorderedMany
            case .toOrderedMany:
                return .toOrderedMany
        }
    }
}

extension RelatedDatabaseRecordIdentifiers {
    mutating func insert(_ element: Database.Record.ID) throws {
        switch self {
            case .toOne:
                throw Error.insertIllegal
            case .toUnorderedMany(let value):
                self = .toUnorderedMany(value.inserting(element))
            case .toOrderedMany(let value):
                self = .toOrderedMany(value.inserting(element))
        }
    }
    
    mutating func remove(_ element: Database.Record.ID) throws {
        switch self {
            case .toOne:
                throw Error.insertIllegal
            case .toUnorderedMany(let value):
                self = .toUnorderedMany(value.removing(element))
            case .toOrderedMany(let value):
                self = .toOrderedMany(value.removing(allOf: element))
        }
    }
    
    func _toCollection() -> any Collection<Database.Record.ID> {
        switch self {
            case .toOne(let value):
                return value.map({ [$0] }) ?? []
            case .toUnorderedMany(let value):
                return value
            case .toOrderedMany(let value):
                return value
        }
    }
}

// MARK: - Conformances -

extension RelatedDatabaseRecordIdentifiers: Diffable {
    public enum Difference {
        case toOne(CollectionOfOne<Database.Record.ID?>.Difference)
        case toUnorderedMany(Set<Database.Record.ID>.Difference)
        case toOrderedMany(Array<Database.Record.ID>.Difference)
    }
    
    public func difference(from other: Self) -> Difference {
        switch (self, other) {
            case (.toOne(let lhs), .toOne(let rhs)):
                return .toOne(CollectionOfOne(lhs).difference(from: CollectionOfOne(rhs)))
            case (.toUnorderedMany(let lhs), .toUnorderedMany(let rhs)):
                return .toUnorderedMany(lhs.difference(from: rhs))
            case (.toOrderedMany(let lhs), .toOrderedMany(let rhs)):
                return .toOrderedMany(lhs.difference(from: rhs))
            default:
                fatalError()
        }
    }
    
    public func applying(_ difference: Difference) -> Self? {
        switch (self, difference) {
            case (.toOne(let lhs), .toOne(let rhs)):
                return CollectionOfOne(lhs).applying(rhs).map({ $0.value }).map(Self.toOne)
            case (.toUnorderedMany(let lhs), .toUnorderedMany(let rhs)):
                return lhs.applying(rhs).map(Self.toUnorderedMany)
            case (.toOrderedMany(let lhs), .toOrderedMany(let rhs)):
                return lhs.applying(rhs).map(Self.toOrderedMany)
            default:
                return nil
        }
    }
}

// MARK: - Auxiliary -

extension RelatedDatabaseRecordIdentifiers where Database == AnyDatabase {
    init<T: SwiftDB.Database>(erasing other: RelatedDatabaseRecordIdentifiers<T>) throws {
        switch other {
            case .toOne(let recordID):
                self = .toOne(recordID.map({ AnyDatabaseRecord.ID(erasing: $0) }))
            case .toUnorderedMany(let recordIDs):
                self = .toUnorderedMany(Set(recordIDs.map(AnyDatabaseRecord.ID.init(erasing:))))
            case .toOrderedMany(let recordIDs):
                self = .toOrderedMany(recordIDs.map(AnyDatabaseRecord.ID.init(erasing:)))
        }
    }
    
    func _cast<T: SwiftDB.Database>(
        to other: RelatedDatabaseRecordIdentifiers<T>.Type
    ) throws -> RelatedDatabaseRecordIdentifiers<T> {
        switch self {
            case .toOne(let recordID):
                return .toOne(try recordID?._cast(to: T.Record.ID.self))
            case .toUnorderedMany(let recordIDs):
                return .toUnorderedMany(Set(try recordIDs.map({ try $0._cast(to: T.Record.ID.self) })))
            case .toOrderedMany(let recordIDs):
                return .toOrderedMany(try recordIDs.map({ try $0._cast(to: T.Record.ID.self) }))
        }
    }
}

extension RelatedDatabaseRecordIdentifiers.Difference where Database == AnyDatabase {
    init<T: SwiftDB.Database>(
        erasing other: RelatedDatabaseRecordIdentifiers<T>.Difference
    ) throws {
        switch other {
            case .toOne(let value):
                self = .toOne(value.map({ AnyDatabase.Record.ID(erasing: $0) }))
            case .toUnorderedMany(let value):
                self = .toUnorderedMany(value.map({ AnyDatabase.Record.ID(erasing: $0) }))
            case .toOrderedMany(let value):
                self = .toOrderedMany(value.map({ AnyDatabase.Record.ID(erasing: $0) }))
        }
    }
    
    func _cast<T: SwiftDB.Database>(
        to other: RelatedDatabaseRecordIdentifiers<T>.Difference.Type
    ) throws -> RelatedDatabaseRecordIdentifiers<T>.Difference {
        switch self {
            case .toOne(let value):
                return try .toOne(value.map({ try $0?._cast(to: T.Record.ID.self) }))
            case .toUnorderedMany(let value):
                return try .toUnorderedMany(value.map({ try $0._cast(to: T.Record.ID.self) }))
            case .toOrderedMany(let value):
                return try .toOrderedMany(value.map({ try $0._cast(to: T.Record.ID.self) }))
        }
    }
}
