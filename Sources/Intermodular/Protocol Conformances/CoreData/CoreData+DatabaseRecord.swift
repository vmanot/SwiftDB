//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData {
    public final class DatabaseRecord {
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
    
    public func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws  {
        let key = key.stringValue
        
        rawObject.willChangeValue(forKey: key)
        
        defer {
            rawObject.didChangeValue(forKey: key)
        }
        
        rawObject.setPrimitiveValue(value, forKey: key)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        if let value = value as? any Entity {
            let record = try AnyDatabaseRecord(from: value)._cast(to: _CoreData.DatabaseRecord.self)
            
            try unsafeEncodeValue(record.rawObject, forKey: key)
        } else if let value = value as? NSAttributeCoder {
            try value.encode(to: rawObject, forKey: key)
        } else if let value = value as? Codable {
            try value.encode(to: self, forKey: key)
        }
    }
    
    public func unsafeDecodeValue(forKey key: CodingKey) throws -> Any? {
        let key = key.stringValue
        
        rawObject.willAccessValue(forKey: key)
        
        defer {
            rawObject.didAccessValue(forKey: key)
        }
        
        return rawObject.primitiveValue(forKey: key)
    }
    
    public func decode<Value>(
        _ valueType: Value.Type,
        forKey key: CodingKey
    ) throws -> Value {
        if let valueType = valueType as? any SwiftDB.Entity.Type {
            let record = AnyDatabaseRecord(erasing: _CoreData.DatabaseRecord(rawObject: try cast(unsafeDecodeValue(forKey: key), to: NSManagedObject.self)))
            
            let transactionContext = try _SwiftDB_TaskLocalValues.transactionContext.unwrap()
            
            let recordContainer = _AnyDatabaseRecordContainer(
                transactionContext: transactionContext,
                recordSchema: try transactionContext.databaseContext.recordSchema(forRecordType: record.recordType),
                record: record
            )
            
            return try cast(valueType.init(from: recordContainer), to: Value.self)
        } else if let valueType = valueType as? NSPrimitiveAttributeCoder.Type {
            return try valueType.decode(from: rawObject, forKey: key) as! Value
        } else if let valueType = valueType as? NSAttributeCoder.Type {
            return try valueType.decode(from: rawObject, forKey: key) as! Value
        } else if let valueType = valueType as? Codable.Type {
            return try valueType.decode(from: self, forKey: key) as! Value
        } else {
            throw DecodingError.some
        }
    }
    
    public func setInitialValue<Value>(
        _ value: @autoclosure () -> Value,
        forKey key: CodingKey
    ) throws {
        if !containsValue(forKey: key) {
            let value = value()
            
            if let value = (value as? _opaque_Optional), value._opaque_Optional_flattening() == nil {
                return
            } else if let value = value as? NSAttributeCoder {
                try value.primitivelyEncode(to: rawObject, forKey: key)
            } else if let value = value as? Codable {
                try value.primitivelyEncode(to: self, forKey: key)
            } else {
                assertionFailure()
            }
        }
    }
    
    public func reference(forKey key: CodingKey) throws -> Reference? {
        if let value = rawObject.value(forKey: key.stringValue) {
            return try Reference(managedObject: cast(value, to: NSManagedObject.self))
        } else {
            return nil
        }
    }
    
    public func setReference(_ reference: Reference?, forKey key: CodingKey) throws {
        if let reference = reference {
            /// Here, the zone ID is unused because CoreData wraps over all its 'zones' at once. This raises concerns about the record context APIs.
            rawObject.setValue(try rawObject.managedObjectContext.unwrap().object(with: reference.recordID.nsManagedObjectID), forKey: key.stringValue)
        } else {
            rawObject.setValue(nil, forKey: key.stringValue)
        }
    }
    
    public func relationship(for key: CodingKey) throws -> Relationship {
        Relationship(record: self, key: key)
    }
}

// MARK: - Auxiliary Implementation -

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
    
    public struct ID: Hashable {
        private let base: NSManagedObjectID
        
        var nsManagedObjectID: NSManagedObjectID {
            base
        }
        
        init(managedObjectID: NSManagedObjectID) {
            self.base = managedObjectID
        }
    }
}

extension _CoreData.DatabaseRecord {
    fileprivate enum DecodingError: Error {
        case some
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
