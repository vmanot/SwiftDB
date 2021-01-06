//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CloudKit {
    public final class DatabaseRecord {
        public struct ID: Codable & Hashable {
            let value: String
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
        .init(value: base.recordID.recordName)
    }
}
