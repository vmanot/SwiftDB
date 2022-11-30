//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public class AnyDatabaseRecord: DatabaseRecord, Identifiable, ObservableObject {    
    fileprivate let base: any DatabaseRecord
    
    public init<Record: DatabaseRecord>(erasing record: Record) {
        assert(!(record is AnyDatabaseRecord))
        
        self.base = record
    }
    
    public convenience init(_ record: AnyDatabaseRecord) {
        self.init(erasing: record.base)
    }
    
    public var id: ID {
        base._opaque_recordID
    }
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.eraseObjectWillChangePublisher()
    }
    
    public var recordType: RecordType {
        .init(erasing: base.recordType)
    }
    
    public var allReservedKeys: [CodingKey] {
        base.allReservedKeys
    }
    
    public var allKeys: [CodingKey] {
        base.allKeys
    }
    
    public func contains(_ key: CodingKey) throws -> Bool {
        try base.contains(key)
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        base.containsValue(forKey: key)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try base.encode(value, forKey: key)
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }
    
    public func removeValueOrRelationship(forKey key: CodingKey) throws {
        try base.removeValueOrRelationship(forKey: key)
    }
        
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try base.relationship(for: key).eraseToAnyDatabaseRelationship()
    }
}

// MARK: - Auxiliary -

extension AnyDatabaseRecord {
    public struct ID: Hashable {
        private let base: AnyHashable
        
        init<T: Hashable>(erasing base: T) {
            assert(!(base is ObjectIdentifier))
            
            self.base = base
        }
        
        public func _cast<T>(to type: T.Type) throws -> T {
            try cast(base.base, to: type)
        }
    }
}

extension AnyDatabaseRecord {
    func _cast<Record: DatabaseRecord>(to recordType: Record.Type) throws -> Record {
        try cast(base, to: recordType)
    }
}

extension DatabaseRecord {
    /// Needed because otherwise the compile resolves the default `ObjectIdentifier` `Identifiable.id` implementation.
    var _opaque_recordID: AnyDatabaseRecord.ID {
        .init(erasing: id)
    }
}
