//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData {
    public final class DatabaseRecord {
        public struct ID: Hashable {
            private let base: NSManagedObjectID
            
            var nsManagedObjectID: NSManagedObjectID {
                base
            }
            
            init(managedObjectID: NSManagedObjectID) {
                self.base = managedObjectID
            }
        }
        
        let base: NSManagedObject
        
        init(base: NSManagedObject) {
            self.base = base
        }
    }
}

extension _CoreData.DatabaseRecord: DatabaseRecord, ObservableObject  {
    public var objectWillChange: ObservableObjectPublisher {
        base.objectWillChange
    }
    
    public var isInitialized: Bool {
        base.managedObjectContext != nil
    }
    
    public static var allReservedKeys: [CodingKey] {
        []
    }
    
    public var allKeys: [CodingKey] {
        base.entity.attributesByName.map({ AnyStringKey(stringValue: $0.key) })
    }
    
    public func contains(_ key: CodingKey) -> Bool {
        base.entity.attributesByName[key.stringValue] != nil
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        base.primitiveValueExists(forKey: key.stringValue)
    }
    
    public func setValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey key: CodingKey) throws {
        base.setValue(value, forKey: key.stringValue)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        if let value = value as? NSAttributeCoder {
            try value.encode(to: base, forKey: AnyCodingKey(key))
        } else if let value = value as? Codable {
            try value.encode(to: self, forKey: AnyCodingKey(key))
        }
    }
    
    fileprivate enum DecodingError: Error {
        case some
    }
    
    public func decode<Value>(_ valueType: Value.Type, forKey key: CodingKey) throws -> Value {
        if let valueType = valueType as? NSPrimitiveAttributeCoder.Type {
            return try valueType.decode(from: base, forKey: AnyCodingKey(key)) as! Value
        } else if let valueType = valueType as? NSAttributeCoder.Type {
            return try valueType.decode(from: base, forKey: AnyCodingKey(key)) as! Value
        } else if let valueType = valueType as? Codable.Type {
            return try valueType.decode(from: self, forKey: key) as! Value
        } else {
            throw DecodingError.some
        }
    }
    
    public func reference(forKey key: CodingKey) throws -> Reference? {
        if let value = base.value(forKey: key.stringValue) {
            return try Reference(managedObject: cast(value, to: NSManagedObject.self))
        } else {
            return nil
        }
    }
    
    public func setReference(_ reference: Reference?, forKey key: CodingKey) throws {
        if let reference = reference {
            /// Here, the zone ID is unused because CoreData wraps over all its 'zones' at once. This raises concerns about the record context APIs.
            base.setValue(try base.managedObjectContext.unwrap().object(with: reference.recordID.nsManagedObjectID), forKey: key.stringValue)
        } else {
            base.setValue(nil, forKey: key.stringValue)
        }
    }
}

// MARK: - Auxiliary Implementation -

fileprivate extension Decodable where Self: Encodable {
    static func decode(from object: _CoreData.DatabaseRecord, forKey key: CodingKey) throws -> Self {
        return try _CodableToNSAttributeCoder<Self>.decode(
            from: object.base,
            forKey: AnyCodingKey(key)
        )
            .value
    }
    
    func encode(to object: _CoreData.DatabaseRecord, forKey key: CodingKey) throws  {
        try _CodableToNSAttributeCoder<Self>(self).encode(
            to: object.base,
            forKey: AnyCodingKey(key)
        )
    }
}
