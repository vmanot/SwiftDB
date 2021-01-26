//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public protocol _opaque_DatabaseRecord: _opaque_ObservableObject, CancellablesHolder {
    var isInitialized: Bool { get }
    
    var allReservedKeys: [CodingKey] { get }
    var allKeys: [CodingKey] { get }
    
    func contains(_ key: CodingKey) -> Bool
    func containsValue(forKey key: CodingKey) -> Bool
    
    func setValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey: CodingKey) throws
    
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
}

public protocol DatabaseRecord: _opaque_DatabaseRecord {
    associatedtype Reference: DatabaseRecordReference
    
    var isInitialized: Bool { get }
    
    var allReservedKeys: [CodingKey] { get }
    var allKeys: [CodingKey] { get }
    
    func contains(_ key: CodingKey) -> Bool
    func containsValue(forKey key: CodingKey) -> Bool
    
    func setValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey: CodingKey) throws
    
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
    
    func reference(forKey key: CodingKey) throws -> Reference?
    func setReference(_ reference: Reference?, forKey key: CodingKey) throws 
}

// MARK: - Implementation -

extension _opaque_DatabaseRecord {
    func decode<Value>(
        _ type: Value.Type,
        forKey key: CodingKey,
        defaultValue: @autoclosure () -> Value
    ) throws -> Value {
        guard containsValue(forKey: key) else {
            return defaultValue()
        }
        
        return try decode(Value.self, forKey: key)
    }
    
    func decode<Value>(
        _ type: Value.Type,
        forKey key: CodingKey,
        initialValue: Value?
    ) throws -> Value {
        if !containsValue(forKey: key) {
            let initialValue = try initialValue.unwrap()
            
            try encode(initialValue, forKey: key)
            
            return initialValue
        }
        
        return try decode(Value.self, forKey: key)
    }
}
