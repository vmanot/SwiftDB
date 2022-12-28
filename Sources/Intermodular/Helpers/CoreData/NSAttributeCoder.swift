//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swallow

/// A CoreData attribute coder.
public protocol NSAttributeCoder {
    static func primitivelyDecode<Key: CodingKey>(from _: NSManagedObject, forKey _: Key) throws -> Self
    static func decode<Key: CodingKey>(from _: KeyValueCoding, forKey _: Key) throws -> Self
    
    func primitivelyEncode<Key: CodingKey>(to _: NSManagedObject, forKey _: Key) throws
    func encode<Key: CodingKey>(to _: KeyValueCoding, forKey _: Key) throws
    
    func getNSAttributeType() -> NSAttributeType
    
    static func toNSAttributeTypeIfPossible() -> NSAttributeType?
}

// MARK: - Default Implementation -

extension NSAttributeCoder {
    public static func primitivelyDecode<Key: CodingKey>(
        from object: NSManagedObject,
        forKey key: Key,
        defaultValue: @autoclosure () -> Self
    ) throws -> Self {
        guard object.primitiveValueExists(forKey: key.stringValue) else {
            let defaultValue = defaultValue()
            
            try defaultValue.primitivelyEncode(to: object, forKey: key)
            
            return defaultValue
        }
        
        return try primitivelyDecode(from: object, forKey: key)
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
    public static func primitivelyDecode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        if object.primitiveValue(forKey: key.stringValue) == nil {
            return .none
        } else {
            return try Wrapped.primitivelyDecode(from: object, forKey: key)
        }
    }
    
    public static func decode<Key: CodingKey>(from object: KeyValueCoding, forKey key: Key) throws -> Self {
        if object.value(forKey: key.stringValue) == nil {
            return .none
        } else {
            return try Wrapped.decode(from: object, forKey: key)
        }
    }
    
    public func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        if let value = self {
            try value.primitivelyEncode(to: object, forKey: key)
        } else {
            object.setPrimitiveValue(nil, forKey: key.stringValue)
        }
    }
    
    public func encode<Key: CodingKey>(to object: KeyValueCoding, forKey key: Key) throws {
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
    public static func primitivelyDecode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try Self(rawValue: try RawValue.primitivelyDecode(from: object, forKey: key)).unwrap()
    }
    
    public static func decode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try Self(rawValue: try RawValue.decode(from: object, forKey: key)).unwrap()
    }
    
    public func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try rawValue.primitivelyEncode(to: object, forKey: key)
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
    public static func primitivelyDecode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        Self(try Value.primitivelyDecode(from: object, forKey: key))
    }
    
    public static func decode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        Self(try Value.decode(from: object, forKey: key))
    }
    
    public func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try value.primitivelyEncode(to: object, forKey: key)
    }
    
    public func encode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try value.encode(to: object, forKey: key)
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        value.getNSAttributeType()
    }
}

// MARK: - Implementations -

struct _CodableToNSAttributeCoder<T: Codable>: NSAttributeCoder, Loggable {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    static func primitivelyDecode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        .init(try ObjectDecoder().decode(T.self, from: object.primitiveValue(forKey: key.stringValue).unwrap()))
    }
    
    static func decode<Key: CodingKey>(from object: KeyValueCoding, forKey key: Key) throws -> Self {
        let value = object.value(forKey: key.stringValue)
        
        if value == nil, let _T = T.self as? _opaque_Optional.Type {
            return .init(_T.init(none: ()) as! T)
        }
        
        return .init(try ObjectDecoder().decode(T.self, from: try value.unwrap()))
    }
    
    func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        guard object.managedObjectContext != nil else {
            return
        }
        
        object.setPrimitiveValue(try ObjectEncoder().encode(value), forKey: key.stringValue)
    }
    
    func encode<Key: CodingKey>(to object: KeyValueCoding, forKey key: Key) throws {
        if let object = object as? NSManagedObject {
            guard object.managedObjectContext != nil else {
                assertionFailure()
                
                return
            }
        }
        
        let value = try ObjectEncoder().encode(value)
        
        if value is NSNull {
            object.setValue(nil, forKey: key.stringValue)
        } else {
            object.setValue(value, forKey: key.stringValue)
        }
    }
    
    func getNSAttributeType() -> NSAttributeType {
        .transformableAttributeType
    }
}

struct _OptionalCodableToNSAttributeCoder<T: Codable>: NSAttributeCoder {
    let value: T?
    
    init(_ value: T?) {
        self.value = value
    }
    
    static func primitivelyDecode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        guard let primitiveValue = object.primitiveValue(forKey: key.stringValue) else {
            return .init(nil)
        }
        
        return .init(try ObjectDecoder().decode(T.self, from: primitiveValue))
    }
    
    static func decode<Key: CodingKey>(from object: KeyValueCoding, forKey key: Key) throws -> Self {
        guard let value = object.value(forKey: key.stringValue) else {
            return .init(nil)
        }
        
        return .init(try ObjectDecoder().decode(T.self, from: value))
    }
    
    func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        guard object.managedObjectContext != nil else {
            return
        }
        
        guard let value = value else {
            return
        }
        
        object.setPrimitiveValue(try ObjectEncoder().encode(value), forKey: key.stringValue)
    }
    
    func encode<Key: CodingKey>(to object: KeyValueCoding, forKey key: Key) throws {
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
    
    func getNSAttributeType() -> NSAttributeType {
        .transformableAttributeType
    }
}

extension NSObject: NSAttributeCoder {
    public static func primitivelyDecode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try cast(object.primitiveValue(forKey: key.stringValue), to: Self.self)
    }
    
    public static func decode<Key: CodingKey>(from object: KeyValueCoding, forKey key: Key) throws -> Self {
        try cast(object.value(forKey: key.stringValue), to: Self.self)
    }
    
    public func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        object.setPrimitiveValue(self, forKey: key.stringValue)
    }
    
    public func encode<Key: CodingKey>(to object: KeyValueCoding, forKey key: Key) throws {
        object.setValue(self, forKey: key.stringValue)
    }
    
    @objc public func getNSAttributeType() -> NSAttributeType {
        .transformableAttributeType
    }
}
