//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit {
    public final class DatabaseRecord {
        // FIXME: Should Zone ID be part of this?
        public struct ID: Codable & Hashable {
            let rawValue: String
            
            init(rawValue: String) {
                self.rawValue = rawValue
            }
            
            init(recordID: CKRecord.ID) {
                self.rawValue = recordID.recordName
            }
        }
        
        public typealias RecordType = String
        
        let ckRecord: CKRecord
        
        init(ckRecord: CKRecord) {
            self.ckRecord = ckRecord
        }
    }
}

extension _CloudKit.DatabaseRecord: DatabaseRecord, ObservableObject {
    public var objectWillChange: ObjectWillChangePublisher {
        .init()
    }
    
    public var recordType: RecordType {
        ckRecord.recordType
    }
    
    public var allReservedKeys: [CodingKey] {
        [AnyCodingKey(stringValue: "systemFields")]
    }
    
    public var allKeys: [CodingKey] {
        ckRecord.allKeys().map({ AnyStringKey(stringValue: $0) })
    }
    
    public func contains(_ key: CodingKey) -> Bool {
        allKeys.contains(where: { AnyCodingKey($0) == .init(key) })
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        ckRecord.object(forKey: key.stringValue) != nil
    }
    
    public func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws {
        ckRecord.setValue(value, forKey: key.stringValue)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        if let value = value as? NSAttributeCoder {
            try value.encode(to: ckRecord, forKey: AnyCodingKey(key))
        } else if let value = value as? Codable {
            try value.encode(to: self, forKey: AnyCodingKey(key))
        }
    }
    
    public func removeValueOrRelationship(forKey key: CodingKey) throws {
        ckRecord.removeObject(forKey: key.stringValue)
    }
        
    public func unsafeDecodeValue(forKey key: CodingKey) -> Any? {
        ckRecord.value(forKey: key.stringValue)
    }
    
    public func decode<Value>(_ valueType: Value.Type, forKey key: CodingKey) throws -> Value {
        if let valueType = valueType as? NSPrimitiveAttributeCoder.Type {
            return try valueType.decode(from: ckRecord, forKey: AnyCodingKey(key)) as! Value
        } else if let valueType = valueType as? NSAttributeCoder.Type {
            return try valueType.decode(from: ckRecord, forKey: AnyCodingKey(key)) as! Value
        } else if let valueType = valueType as? Codable.Type {
            return try valueType.decode(from: self, forKey: key) as! Value
        } else {
            throw DecodingError.some
        }
    }
}

extension _CloudKit.DatabaseRecord: Identifiable {
    public var id: ID {
        .init(rawValue: ckRecord.recordID.recordName)
    }
}

// MARK: - Auxiliary -

extension _CloudKit.DatabaseRecord {
    fileprivate enum DecodingError: Error {
        case some
    }
}

fileprivate extension Decodable where Self: Encodable {
    static func decode(from object: _CloudKit.DatabaseRecord, forKey key: CodingKey) throws -> Self {
        return try _CodableToNSAttributeCoder<Self>.decode(
            from: object.ckRecord,
            forKey: AnyCodingKey(key)
        )
        .value
    }
    
    func encode(to object: _CloudKit.DatabaseRecord, forKey key: CodingKey) throws  {
        try _CodableToNSAttributeCoder<Self>(self).encode(
            to: object.ckRecord,
            forKey: AnyCodingKey(key)
        )
    }
}
