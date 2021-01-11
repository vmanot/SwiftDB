//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swallow

@propertyWrapper
public struct NSAttribute<Value> {
    public let key: AnyStringKey
    public var wrappedValue: Value
    
    @usableFromInline
    let decodeImpl: (NSManagedObject) throws -> Value
    @usableFromInline
    let encodeImpl: (Value, NSManagedObject) throws -> Void
    
    @inlinable
    public static subscript<EnclosingSelf: NSManagedObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            try! object[keyPath: storageKeyPath].decodeImpl(object)
        } set {
            try! object[keyPath: storageKeyPath].encodeImpl(newValue, object)
            object[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

extension NSAttribute where Value: Codable {
    @inlinable
    public init(key: String, defaultValue: Value) {
        self.key = .init(stringValue: key)
        self.wrappedValue = defaultValue
        
        self.decodeImpl = { try _CodableToNSAttributeCoder<Value>.decode(from: $0, forKey: AnyStringKey(stringValue: key), defaultValue: .init(defaultValue)).value }
        self.encodeImpl = { try _CodableToNSAttributeCoder($0).encode(to: $1, forKey: AnyStringKey(stringValue: key)) }
    }
    
    @inlinable
    public init<T: Codable>(key: String, defaultValue: Value = .none) where Value == Optional<T> {
        self.key = .init(stringValue: key)
        self.wrappedValue = defaultValue
        
        self.decodeImpl = { try _OptionalCodableToNSAttributeCoder<T>.decode(from: $0, forKey: AnyStringKey(stringValue: key), defaultValue: .init(defaultValue)).value }
        self.encodeImpl = { try _OptionalCodableToNSAttributeCoder($0).encode(to: $1, forKey: AnyStringKey(stringValue: key)) }
    }
}

extension NSAttribute where Value: NSAttributeCoder {
    @inlinable
    public init(key: String, defaultValue: Value) {
        self.key = .init(stringValue: key)
        self.wrappedValue = defaultValue
        
        self.decodeImpl = { try Value.decode(from: $0, forKey: AnyStringKey(stringValue: key), defaultValue: defaultValue) }
        self.encodeImpl = { try $0.encode(to: $1, forKey: AnyStringKey(stringValue: key)) }
    }
    
    @inlinable
    public init<T>(key: String) where Value == Optional<T> {
        self.init(key: key, defaultValue: .none)
    }
}

// MARK: - Auxiliary Implementation -

public struct _CodableToNSAttributeCoder<T: Codable>: NSAttributeCoder {
    public let value: T
    
    @inlinable
    public init(_ value: T) {
        self.value = value
    }
    
    @inlinable
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        .init(try ObjectDecoder().decode(T.self, from: object.primitiveValue(forKey: key.stringValue).unwrap()))
    }
    
    @inlinable
    public static func decode<Key: CodingKey>(from object: KeyValueCoder, forKey key: Key) throws -> Self {
        let value = object.value(forKey: key.stringValue)
        
        if value == nil, let _T = T.self as? _opaque_Optional.Type {
            return .init(_T.init(none: ()) as! T)
        }
        
        return .init(try ObjectDecoder().decode(T.self, from: try value.unwrap()))
    }
    
    @inlinable
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        guard object.managedObjectContext != nil else {
            return
        }
        
        object.setPrimitiveValue(try ObjectEncoder().encode(value), forKey: key.stringValue)
    }
    
    @inlinable
    public func encode<Key: CodingKey>(to object: KeyValueCoder, forKey key: Key) throws {
        if let object = object as? NSManagedObject {
            guard object.managedObjectContext != nil else {
                return
            }
        }

        object.setValue(try ObjectEncoder().encode(value), forKey: key.stringValue)
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        .transformableAttributeType
    }
}

public struct _OptionalCodableToNSAttributeCoder<T: Codable>: NSAttributeCoder {
    public let value: T?
    
    @inlinable
    public init(_ value: T?) {
        self.value = value
    }
    
    @inlinable
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        guard let primitiveValue = object.primitiveValue(forKey: key.stringValue) else {
            return .init(nil)
        }
        
        return .init(try ObjectDecoder().decode(T.self, from: primitiveValue))
    }
    
    @inlinable
    public static func decode<Key: CodingKey>(from object: KeyValueCoder, forKey key: Key) throws -> Self {
        guard let value = object.value(forKey: key.stringValue) else {
            return .init(nil)
        }
        
        return .init(try ObjectDecoder().decode(T.self, from: value))
    }
    
    @inlinable
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        guard object.managedObjectContext != nil else {
            return
        }
        
        guard let value = value else {
            return
        }
        
        object.setPrimitiveValue(try ObjectEncoder().encode(value), forKey: key.stringValue)
    }
    
    @inlinable
    public func encode<Key: CodingKey>(to object: KeyValueCoder, forKey key: Key) throws {
        if let object = object as? NSManagedObject {
            guard object.managedObjectContext != nil else {
                return
            }
        }
        
        guard let value = value else {
            return
        }
        
        object.setValue(try ObjectEncoder().encode(value), forKey: key.stringValue)
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        .transformableAttributeType
    }
}
