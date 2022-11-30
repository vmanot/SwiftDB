//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

extension _CoreData {
    public final class DatabaseRecord {
        private enum Error: Swift.Error {
            case failedToDecodeValueForKey(CodingKey)
            case attemptedToEncodeRelationshipAsValue(CodingKey)
        }
        
        public lazy var cancellables = Cancellables()
        
        let rawObject: NSManagedObject
        
        init(rawObject: NSManagedObject) {
            self.rawObject = rawObject
        }
    }
}

extension _CoreData.DatabaseRecord: DatabaseRecord, ObservableObject {
    public var recordType: _CoreData.DatabaseRecord.RecordType {
        .init(rawValue: rawObject.entity.name!) // FIXME
    }
    
    public var id: ID {
        ID(managedObjectID: rawObject.objectID)
    }
    
    public var objectWillChange: ObservableObjectPublisher {
        rawObject.objectWillChange
    }
    
    public var isInitialized: Bool {
        rawObject.managedObjectContext != nil
    }
    
    public var allReservedKeys: [CodingKey] {
        []
    }
    
    public var allKeys: [CodingKey] {
        rawObject.entity.attributesByName.map({ AnyStringKey(stringValue: $0.key) })
    }
    
    public func contains(_ key: CodingKey) -> Bool {
        rawObject.entity.attributesByName[key.stringValue] != nil || rawObject.entity.relationshipsByName[key.stringValue] != nil
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        rawObject.primitiveValueExists(forKey: key.stringValue)
    }
    
    public func decode<Value>(
        _ valueType: Value.Type,
        forKey key: CodingKey
    ) throws -> Value {
        if let valueType = valueType as? NSPrimitiveAttributeCoder.Type {
            return try valueType.decode(from: rawObject, forKey: key) as! Value
        } else if let valueType = valueType as? NSAttributeCoder.Type {
            return try valueType.decode(from: rawObject, forKey: key) as! Value
        } else if let valueType = valueType as? Codable.Type {
            return try valueType.decode(from: self, forKey: key) as! Value
        } else {
            throw Error.failedToDecodeValueForKey(key)
        }
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        guard rawObject.entity.relationshipsByName[key.stringValue] == nil else {
            throw Error.attemptedToEncodeRelationshipAsValue(key)
        }
        
        if let value = value as? NSAttributeCoder {
            try value.encode(to: rawObject, forKey: key)
        } else if let value = value as? Codable {
            try value.encode(to: self, forKey: key)
        }
    }
    
    public func removeValueOrRelationship(forKey key: CodingKey) throws {
        try unsafeEncodeValue(nil, forKey: key)
    }
            
    public func relationship(for key: CodingKey) throws -> Relationship {
        Relationship(record: self, key: key)
    }
    
    func unsafeDecodeValue(forKey key: CodingKey) throws -> Any? {
        let key = key.stringValue
        
        rawObject.willAccessValue(forKey: key)
        
        defer {
            rawObject.didAccessValue(forKey: key)
        }
        
        return rawObject.primitiveValue(forKey: key)
    }
    
    func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws  {
        let key = key.stringValue
        
        rawObject.willChangeValue(forKey: key)
        
        defer {
            rawObject.didChangeValue(forKey: key)
        }
        
        rawObject.setPrimitiveValue(value, forKey: key)
    }
}

// MARK: - Auxiliary -

extension _CoreData.DatabaseRecord {
    public struct RecordType: Codable, CustomStringConvertible, Hashable, LosslessStringConvertible {
        public let rawValue: String
        
        public var description: String {
            rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ description: String) {
            self.rawValue = description
        }
    }
    
    public struct ID: Hashable, PredicateExpressionPrimitiveConvertible {
        private let base: NSManagedObjectID
        
        var nsManagedObjectID: NSManagedObjectID {
            base
        }
        
        init(managedObjectID: NSManagedObjectID) {
            self.base = managedObjectID
        }
        
        public func toPredicateExpressionPrimitive() -> PredicateExpressionPrimitive {
            base // FIXME: Is this a valid `NSPredicate` expression primitive?
        }
    }
}

fileprivate extension Decodable where Self: Encodable {
    static func decode(from object: _CoreData.DatabaseRecord, forKey key: CodingKey) throws -> Self {
        return try _CodableToNSAttributeCoder<Self>.decode(
            from: object.rawObject,
            forKey: AnyCodingKey(key)
        )
        .value
    }
    
    func encode(to object: _CoreData.DatabaseRecord, forKey key: CodingKey) throws  {
        try _CodableToNSAttributeCoder<Self>(self).encode(
            to: object.rawObject,
            forKey: AnyCodingKey(key)
        )
    }
    
    func primitivelyEncode(to object: _CoreData.DatabaseRecord, forKey key: CodingKey) throws  {
        try _CodableToNSAttributeCoder<Self>(self).primitivelyEncode(
            to: object.rawObject,
            forKey: AnyCodingKey(key)
        )
    }
}
