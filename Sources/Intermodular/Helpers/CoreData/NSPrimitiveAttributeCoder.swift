//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swallow

public protocol NSPrimitiveAttributeCoder: NSAttributeCoder {
    static func toNSAttributeType() -> NSAttributeType
}

// MARK: - Implementation -

extension NSPrimitiveAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try cast(object.primitiveValue(forKey: key.stringValue), to: Self.self)
    }
    
    public static func decode<Key: CodingKey>(from object: KeyValueCoder, forKey key: Key) throws -> Self {
        let key = key.stringValue
        
        if let object = object as? NSManagedObject {
            object.willAccessValue(forKey: key)
            
            defer {
                object.didAccessValue(forKey: key)
            }
            
            return try cast(object.primitiveValue(forKey: key), to: Self.self)
        } else {
            return object.value(forKey: key) as! Self
        }
    }
    
    public func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) {
        guard object.managedObjectContext != nil else {
            return
        }
        
        return object.setPrimitiveValue(self, forKey: key.stringValue)
    }
    
    public func encode<Key: CodingKey>(to object: KeyValueCoder, forKey key: Key) {
        let key = key.stringValue
        
        if let object = object as? NSManagedObject {
            guard object.managedObjectContext != nil else {
                return
            }
            
            object.willChangeValue(forKey: key)
            
            defer {
                object.didChangeValue(forKey: key)
            }
            
            return object.setPrimitiveValue(self, forKey: key)
        } else {
            object.setValue(self, forKey: key)
        }
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        Self.toNSAttributeType()
    }
    
    public static func toNSAttributeTypeIfPossible() -> NSAttributeType? {
        Self.toNSAttributeType()
    }
}

// MARK: - Conditional Conformances -

extension Optional: NSPrimitiveAttributeCoder where Wrapped: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        Wrapped.toNSAttributeType()
    }
}

extension RawRepresentable where RawValue: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        RawValue.toNSAttributeType()
    }
}

// MARK: - Conformances -

extension Bool: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .booleanAttributeType
    }
}

extension Character: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        String.toNSAttributeType()
    }
    
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) throws -> Self {
        try .init(String.decodePrimitive(from: object, forKey: key))
    }

    public static func decode<Key: CodingKey>(from object: KeyValueCoder, forKey key: Key) throws -> Self {
        try .init(String.decode(from: object, forKey: key))
    }

    public func primitivelyEncode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try stringValue.primitivelyEncode(to: object, forKey: key)
    }

    public func encode<Key: CodingKey>(to object: KeyValueCoder, forKey key: Key) {
        stringValue.encode(to: object, forKey: key)
    }
}

extension Date: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .dateAttributeType
    }
}

extension Data: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .binaryDataAttributeType
    }
}

extension Decimal: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .decimalAttributeType
    }
}

extension Double: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .doubleAttributeType
    }
}

extension Float: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .floatAttributeType
    }
}

extension Int: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .integer64AttributeType
    }
}

extension Int16: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .integer16AttributeType
    }
}

extension Int32: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .integer32AttributeType
    }
}

extension Int64: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .integer64AttributeType
    }
}

extension NSNumber {
    override public func getNSAttributeType() -> NSAttributeType {
        if let value = downcast() as? NSPrimitiveAttributeCoder {
            return value.getNSAttributeType()
        } else {
            assertionFailure()
            
            return .decimalAttributeType
        }
    }
}

extension String: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .stringAttributeType
    }
}

extension URL: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .URIAttributeType
    }
}

extension UUID: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .UUIDAttributeType
    }
}
