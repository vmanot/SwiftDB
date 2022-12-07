//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import Swift

/// A database record.
public protocol DatabaseRecord: Identifiable, CancellablesHolder {
    associatedtype Database: SwiftDB.Database where Database.Record == Self
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    
    typealias RelatedRecordIdentifiers = RelatedDatabaseRecordIdentifiers<Database>

    var recordType: RecordType { get }

    var allReservedKeys: [AnyCodingKey] { get }
    var allKeys: [AnyCodingKey] { get }

    /// Returns a Boolean value that indicates whether a key is known to be supported by this record.
    func containsKey(_ key: AnyCodingKey) throws -> Bool

    /// Returns a Boolean value that indicates whether an encoded value is present for the given key.
    func containsValue(forKey key: AnyCodingKey) -> Bool

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type value to decode.
    /// - parameter key: The key that the value is associated with.
    func decode<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value

    func decodeRelationship(
        ofType type: DatabaseRecordRelationshipType,
        forKey key: AnyCodingKey
    ) throws -> RelatedRecordIdentifiers
}

public enum DatabaseRecordRelationshipType {
    case toOne
    case toUnorderedMany
    case toOrderedMany
}

public enum RelatedDatabaseRecordIdentifiers<Database: SwiftDB.Database> {
    case toOne(Database.Record.ID?)
    case toUnorderedMany(Set<Database.Record.ID>)
    case toOrderedMany(Array<Database.Record.ID>)
}

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
