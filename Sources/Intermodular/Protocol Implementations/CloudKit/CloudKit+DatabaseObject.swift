//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CloudKit {
    struct DatabaseObject {
        struct ID: Hashable {
            let base: CKRecord.ID
        }
        
        let base: CKRecord
    }
}

extension _CloudKit.DatabaseObject: DatabaseObject {
    var isInitialized: Bool {
        true
    }
    
    var allKeys: [CodingKey] {
        base.allKeys().map({ AnyStringKey(stringValue: $0) })
    }
    
    func contains(_ key: CodingKey) -> Bool {
        allKeys.contains(where: { AnyCodingKey($0) == .init(key) })
    }
    
    func containsValue(forKey key: CodingKey) -> Bool {
        base.object(forKey: key.stringValue) != nil
    }
    
    func setValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey key: CodingKey) throws {
        base.setValue(value, forKey: key.stringValue)
    }
    
    func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        fatalError()
    }
    
    func decode<Value>(_: Value.Type, forKey key: CodingKey) throws -> Value {
        fatalError()
    }
}
