//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import Swift

/// A database record.
public protocol DatabaseRecord: ObservableObject, Identifiable, CancellablesHolder {
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    associatedtype Reference: DatabaseRecordReference
    associatedtype Relationship: DatabaseRecordRelationship = NoDatabaseRecordRelationship<Self>
    
    var recordType: RecordType { get }
    
    var allReservedKeys: [CodingKey] { get }
    var allKeys: [CodingKey] { get }
    
    /// Returns a Boolean value that indicates whether a key is known to be supported by this record.
    func contains(_ key: CodingKey) -> Bool
    
    /// Returns a Boolean value that indicates whether an encoded value is present for the given key.
    func containsValue(forKey key: CodingKey) -> Bool
    
    /// Encodes a value for the given key.
    ///
    /// - parameter value: The value to encode.
    /// - parameter key: The key to associate the value with.
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    
    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type value to decode.
    /// - parameter key: The key that the value is associated with.
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
    
    func setInitialValue<Value>(_ value: @autoclosure() -> Value, forKey key: CodingKey) throws
        
    func relationship(for key: CodingKey) throws -> Relationship
}
