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
