//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swallow

/// A CoreData attribute coder.
public protocol NSAttributeCoder {
    static func decodePrimitive<Key: CodingKey>(from _: NSManagedObject, forKey _: Key) throws -> Self
    static func decode<Key: CodingKey>(from _: KeyValueCoder, forKey _: Key) throws -> Self
    
    func encodePrimitive<Key: CodingKey>(to _: NSManagedObject, forKey _: Key) throws
    func encode<Key: CodingKey>(to _: KeyValueCoder, forKey _: Key) throws
    
    func getNSAttributeType() -> NSAttributeType
    
    static func toNSAttributeTypeIfPossible() -> NSAttributeType?
}

// MARK: - Implementation -

extension NSAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(
        from object: NSManagedObject,
        forKey key: Key,
        defaultValue: @autoclosure () -> Self
    ) throws -> Self {
        guard object.primitiveValueExists(forKey: key.stringValue) else {
            let defaultValue = defaultValue()
            
            try defaultValue.encodePrimitive(to: object, forKey: key)
            
            return defaultValue
        }
        
        return try decodePrimitive(from: object, forKey: key)
    }
    
    public static func decode<Key: CodingKey>(
        from object: NSManagedObject,
        forKey key: Key,
        defaultValue: @autoclosure () -> Self
    ) throws -> Self {
        guard object.primitiveValueExists(forKey: key.stringValue) else {
            let defaultValue = defaultValue()
            
            try defaultValue.encode(to: object, forKey: key)
            
            return defaultValue
        }
        
        return try decode(from: object, forKey: key)
    }
    
    public static func toNSAttributeTypeIfPossible() -> NSAttributeType? {
        return nil
    }
}

// MARK: - Conditional Conformance -

extension Optional: NSAttributeCoder where Wrapped: NSAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        if object.primitiveValue(forKey: key.stringValue) == nil {
            return .none
        } else {
            return try Wrapped.decodePrimitive(from: object, forKey: key)
        }
    }
    
    public static func decode<Key: CodingKey>(from object: KeyValueCoder, forKey key: Key) throws -> Self {
        if object.value(forKey: key.stringValue) == nil {
            return .none
        } else {
            return try Wrapped.decode(from: object, forKey: key)
        }
    }
    
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        if let value = self {
            try value.encodePrimitive(to: object, forKey: key)
        } else {
            object.setPrimitiveValue(nil, forKey: key.stringValue)
        }
    }
    
    public func encode<Key: CodingKey>(to object: KeyValueCoder, forKey key: Key) throws {
        if let value = self {
            try value.encode(to: object, forKey: key)
        } else {
            object.setValue(nil, forKey: key.stringValue)
        }
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        if let wrapped = self {
            return wrapped.getNSAttributeType()
        } else if let result = Wrapped.toNSAttributeTypeIfPossible() {
            return result
        } else if let wrappedType = Wrapped.self as? ExpressibleByNilLiteral.Type {
            return (wrappedType.init(nilLiteral: ()) as! Wrapped).getNSAttributeType()
        } else if let wrappedType = Wrapped.self as? Initiable.Type {
            return (wrappedType.init() as! Wrapped).getNSAttributeType()
        } else {
            return .undefinedAttributeType
        }
    }
    
    public static func toNSAttributeTypeIfPossible() -> NSAttributeType? {
        Wrapped.toNSAttributeTypeIfPossible() ?? Optional.none.getNSAttributeType()
    }
}

extension RawRepresentable where RawValue: NSAttributeCoder, Self: NSAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try Self(rawValue: try RawValue.decodePrimitive(from: object, forKey: key)).unwrap()
    }
    
    public static func decode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try Self(rawValue: try RawValue.decode(from: object, forKey: key)).unwrap()
    }
    
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try rawValue.encodePrimitive(to: object, forKey: key)
    }
    
    public func encode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try rawValue.encode(to: object, forKey: key)
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        rawValue.getNSAttributeType()
    }
    
    public static func toNSAttributeTypeIfPossible() -> NSAttributeType? {
        RawValue.toNSAttributeTypeIfPossible()
    }
}

extension Wrapper where Value: NSAttributeCoder, Self: NSAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        Self(try Value.decodePrimitive(from: object, forKey: key))
    }
    
    public static func decode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        Self(try Value.decode(from: object, forKey: key))
    }
    
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try value.encodePrimitive(to: object, forKey: key)
    }
    
    public func encode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try value.encode(to: object, forKey: key)
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        value.getNSAttributeType()
    }
}

// MARK: - Conformances -

extension NSObject: NSAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try cast(object.primitiveValue(forKey: key.stringValue), to: Self.self)
    }
    
    public static func decode<Key: CodingKey>(from object: KeyValueCoder, forKey key: Key) throws -> Self {
        try cast(object.value(forKey: key.stringValue), to: Self.self)
    }
    
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        object.setPrimitiveValue(self, forKey: key.stringValue)
    }
    
    public func encode<Key: CodingKey>(to object: KeyValueCoder, forKey key: Key) throws {
        object.setValue(self, forKey: key.stringValue)
    }
    
    @objc public func getNSAttributeType() -> NSAttributeType {
        .transformableAttributeType
    }
}
