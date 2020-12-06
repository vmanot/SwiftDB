//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _opaque_DatabaseObject {
    
}

public protocol DatabaseObject: _opaque_DatabaseObject {
    var isInitialized: Bool { get }
    var allKeys: [CodingKey] { get }
    
    func contains(_ key: CodingKey) -> Bool
    func containsValue(forKey key: CodingKey) -> Bool
    
    func setValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey: CodingKey) throws
    
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws
    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value
}

// MARK: - Implementation -

extension DatabaseObject {
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
