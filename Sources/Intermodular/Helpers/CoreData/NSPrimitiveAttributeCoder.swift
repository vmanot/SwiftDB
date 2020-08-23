//
// Copyright (c) Vatsal Manot
//

import Foundation
import CoreData
import Swallow

public protocol NSPrimitiveAttributeCoder: NSAttributeCoder {
    static func toNSAttributeType() -> NSAttributeType
}

// MARK: - Implementation -

extension NSPrimitiveAttributeCoder {
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) -> Self {
        object.primitiveValue(forKey: key.stringValue) as! Self
    }
    
    public static func decode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) -> Self {
        let key = key.stringValue
        
        object.willAccessValue(forKey: key)
        
        defer {
            object.didAccessValue(forKey: key)
        }
        
        return object.primitiveValue(forKey: key) as! Self
    }
    
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) {
        guard object.managedObjectContext != nil else {
            return
        }
        
        return object.setPrimitiveValue(self, forKey: key.stringValue)
    }
    
    public func encode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) {
        guard object.managedObjectContext != nil else {
            return
        }

        let key = key.stringValue
        
        object.willChangeValue(forKey: key)
        
        defer {
            object.didChangeValue(forKey: key)
        }
        
        return object.setPrimitiveValue(self, forKey: key)
    }
    
    public func getNSAttributeType() -> NSAttributeType {
        Self.toNSAttributeType()
    }
}

// MARK: - Conditional Conformances -

extension Optional: NSPrimitiveAttributeCoder where Wrapped: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        Wrapped.toNSAttributeType()
    }
}

// MARK: - Concrete Implementations -

extension Bool: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        .booleanAttributeType
    }
}

extension Character: NSPrimitiveAttributeCoder {
    public static func toNSAttributeType() -> NSAttributeType {
        String.toNSAttributeType()
    }
    
    public static func decodePrimitive<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) -> Self {
        .init(String.decodePrimitive(from: object, forKey: key))
    }
    
    public static func decode<Key: CodingKey>(from object: NSManagedObject, forKey key: Key) -> Self {
        .init(String.decode(from: object, forKey: key))
    }
    
    public func encodePrimitive<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) throws {
        try stringValue.encodePrimitive(to: object, forKey: key)
    }
    
    public func encode<Key: CodingKey>(to object: NSManagedObject, forKey key: Key) {
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
