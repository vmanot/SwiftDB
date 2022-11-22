//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public class AnyDatabaseRecord: DatabaseRecord, Identifiable, ObservableObject {
    public struct ID: Hashable {
        private let base: AnyHashable
        
        init<T: Hashable>(erasing base: T) {
            self.base = base
        }
        
        public func _cast<T>(to type: T.Type) throws -> T {
            try cast(base.base, to: type)
        }
    }
    
    public typealias Reference = NoDatabaseRecordReference<ID> // FIXME!!!
    
    fileprivate let base: any DatabaseRecord
    
    private init(base: any DatabaseRecord) {
        self.base = base
    }
    
    public convenience init<Record: DatabaseRecord>(erasing record: Record) {
        self.init(base: record)
    }
    
    public var id: ID {
        .init(erasing: base.id)
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
    
    public func setInitialValue<Value>(_ value: @autoclosure () -> Value, forKey key: CodingKey) throws {
        try base.setInitialValue(value(), forKey: key)
    }
    
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        try base.relationship(for: key).eraseToAnyDatabaseRelationship()
    }
}

// MARK: - Supplementary API -

extension AnyDatabaseRecord {
    public convenience init<E: Entity>(from entity: E) throws {
        try self.init(base: entity._databaseRecordProxy.record.base)
    }
    
    public func _cast<Record: DatabaseRecord>(to recordType: Record.Type) throws -> Record {
        try cast(base, to: recordType)
    }
}
