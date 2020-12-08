//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CloudKit {
    public final class DatabaseObject {
        public struct ID: Hashable {
            let base: CKRecord.ID
        }
        
        let base: CKRecord
        
        init(base: CKRecord) {
            self.base = base
        }
    }
}

extension _CloudKit.DatabaseObject: DatabaseObject {
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
