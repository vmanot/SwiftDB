//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit {
    public final class DatabaseRecord {
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
        
        let base: CKRecord
        
        init(ckRecord: CKRecord) {
            self.base = ckRecord
        }
    }
}

extension _CloudKit.DatabaseRecord: DatabaseRecord, ObservableObject {
    public var objectWillChange: ObjectWillChangePublisher {
        .init()
    }
    
    public var recordType: RecordType {
        base.recordType
    }
    
    public var allReservedKeys: [CodingKey] {
        [AnyCodingKey(stringValue: "systemFields")]
    }
    
    public var allKeys: [CodingKey] {
        base.allKeys().map({ AnyStringKey(stringValue: $0) })
    }
    
    public func contains(_ key: CodingKey) -> Bool {
        allKeys.contains(where: { AnyCodingKey($0) == .init(key) })
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        base.object(forKey: key.stringValue) != nil
    }
    
    public func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws {
        base.setValue(value, forKey: key.stringValue)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        if let value = value as? NSAttributeCoder {
            try value.encode(to: base, forKey: AnyCodingKey(key))
        } else if let value = value as? Codable {
            try value.encode(to: self, forKey: AnyCodingKey(key))
        }
    }
    
    public func setInitialValue<Value>(
        _ value: @autoclosure () -> Value,
        forKey key: CodingKey
    ) throws {
        guard !containsValue(forKey: key) else {
            return
        }
        
        let value = value()
        
        try encode(value, forKey: key)
    }
    
    fileprivate enum DecodingError: Error {
        case some
    }
    
    public func unsafeDecodeValue(forKey key: CodingKey) -> Any? {
        base.value(forKey: key.stringValue)
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
        Reference(reference: try cast(try base.value(forKey: key.stringValue).unwrap(), to: CKRecord.Reference.self))
    }
    
    public func setReference(_ reference: Reference?, forKey key: CodingKey) throws  {
        base.setValue(reference?.ckReference, forKey: key.stringValue)
    }
}

extension _CloudKit.DatabaseRecord: Identifiable {
    public var id: ID {
        .init(rawValue: base.recordID.recordName)
    }
}

// MARK: - Auxiliary Implementation -

fileprivate extension Decodable where Self: Encodable {
    static func decode(from object: _CloudKit.DatabaseRecord, forKey key: CodingKey) throws -> Self {
        return try _CodableToNSAttributeCoder<Self>.decode(
            from: object.base,
            forKey: AnyCodingKey(key)
        )
        .value
    }
    
    func encode(to object: _CloudKit.DatabaseRecord, forKey key: CodingKey) throws  {
        try _CodableToNSAttributeCoder<Self>(self).encode(
            to: object.base,
            forKey: AnyCodingKey(key)
        )
    }
}
