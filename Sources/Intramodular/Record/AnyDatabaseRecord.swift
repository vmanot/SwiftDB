//
// Copyright (c) Vatsal Manot
//

import Merge
import Swift

public class AnyDatabaseRecord: _opaque_DatabaseRecord, _opaque_ObservableObject, Identifiable, ObservableObject {
    private let base: _opaque_DatabaseRecord
    
    public init(base: _opaque_DatabaseRecord) {
        self.base = base
    }
    
    public var id: AnyHashable {
        base._opaque_id
    }
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base._opaque_objectWillChange
    }
    
    public var isInitialized: Bool {
        base.isInitialized
    }
    
    public var allReservedKeys: [CodingKey] {
        base.allReservedKeys
    }
    
    public var allKeys: [CodingKey] {
        base.allKeys
    }
    
    public func contains(_ key: CodingKey) -> Bool {
        base.contains(key)
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        base.containsValue(forKey: key)
    }
    
    public func encodePrimitiveValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey key: CodingKey) throws {
        try base.encodePrimitiveValue(value, forKey: key)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try base.encode(value, forKey: key)
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }
}
