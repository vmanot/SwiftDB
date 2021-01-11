//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CloudKit {
    public final class DatabaseRecord {
        public struct ID: Codable & Hashable {
            let rawValue: String
        }
        
        let base: CKRecord
        
        init(base: CKRecord) {
            self.base = base
        }
    }
}

extension _CloudKit.DatabaseRecord: DatabaseRecord {
    public var isInitialized: Bool {
        true
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
    
    public func setValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey key: CodingKey) throws {
        base.setValue(value, forKey: key.stringValue)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        fatalError()
    }
    
    public func decode<Value>(_: Value.Type, forKey key: CodingKey) throws -> Value {
        fatalError()
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
