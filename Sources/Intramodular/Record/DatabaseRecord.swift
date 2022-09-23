//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import Swift

/// An opaque mirror for `DatabaseRecord` used by the SwiftDB runtime.
public protocol _opaque_DatabaseRecord: _opaque_Identifiable, _opaque_ObservableObject, CancellablesHolder {
    var isInitialized: Bool { get }
    
    var allReservedKeys: [CodingKey] { get }
    var allKeys: [CodingKey] { get }
    
    func contains(_ key: CodingKey) -> Bool
    func containsValue(forKey key: CodingKey) -> Bool
    
    func primitivelyEncodeValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey key: CodingKey) throws
    
    func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    func unsafeDecodeValue(forKey key: CodingKey) throws -> Any?
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
    
    func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws

    func relatedRecords(forKey key: CodingKey) async throws -> [_opaque_DatabaseRecord]
    
    func _opaque_relationship(forKey key: CodingKey) throws -> _opaque_DatabaseRecordRelationship
}

extension _opaque_DatabaseRecord where Self: DatabaseRecord {
    public func _opaque_relationship(forKey key: CodingKey) throws -> _opaque_DatabaseRecordRelationship {
        try relationship(for: key)
    }
}

/// A database record.
public protocol DatabaseRecord: _opaque_DatabaseRecord, Identifiable {
    associatedtype Reference: DatabaseRecordReference
    associatedtype Relationship: DatabaseRecordRelationship = NoDatabaseRecordRelationship<Self>
    
    var isInitialized: Bool { get }
    
    var allReservedKeys: [CodingKey] { get }
    var allKeys: [CodingKey] { get }
    
    /// Returns a Boolean value that indicates whether a key is known to be supported by this record.
    func contains(_ key: CodingKey) -> Bool
    
    /// Returns a Boolean value that indicates whether an encoded value is present for the given key.
    func containsValue(forKey key: CodingKey) -> Bool
    
    /// Unsafely encode a value for a given key.
    func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws
        
    /// Encode a primitive value for a given key.
    func primitivelyEncodeValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey: CodingKey) throws
    
    /// Encodes a value for the given key.
    ///
    /// - parameter value: The value to encode.
    /// - parameter key: The key to associate the value with.
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    
    /// Unsafely decode a value for a given key.
    func unsafeDecodeValue(forKey key: CodingKey) throws -> Any?

    /// Decodes a value of the given type for the given key.
    ///
    /// - parameter type: The type value to decode.
    /// - parameter key: The key that the value is associated with.
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
    
    func setInitialValue<Value>(_ value: @autoclosure() -> Value, forKey key: CodingKey) throws
    
    func reference(forKey key: CodingKey) throws -> Reference?
    func setReference(_ reference: Reference?, forKey key: CodingKey) throws
    
    func relationship(for key: CodingKey) throws -> Relationship
}

// MARK: - Implementation -

extension DatabaseRecord where Reference == NoDatabaseRecordReference<ID> {
    public func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws {
        throw Never.Reason.unsupported
    }

    public func reference(forKey key: CodingKey) throws -> Reference? {
        throw Never.Reason.unsupported
    }

    public func setReference(_ reference: Reference?, forKey key: CodingKey) throws {
        throw Never.Reason.unsupported
    }
}
