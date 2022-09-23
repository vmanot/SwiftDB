//
// Copyright (c) Vatsal Manot
//

import Merge
import Swift

public class AnyDatabaseRecord: _opaque_DatabaseRecord, _opaque_ObservableObject, DatabaseRecord, Identifiable, ObservableObject {
    public struct ID: Hashable {
        public let base: AnyHashable
    
        init(base: AnyHashable) {
            self.base = base
        }
    }
    
    public struct RecordType: Codable, Hashable, LosslessStringConvertible {
        public let rawValue: String
        
        public var description: String {
            rawValue
        }
        
        public init<T: LosslessStringConvertible>(from value: T) {
            self.rawValue = value.description
        }
        
        public init(_ description: String) {
            self.rawValue = description
        }
    }
    
    public typealias Reference = NoDatabaseRecordReference<ID> // FIXME!!!

    let base: _opaque_DatabaseRecord
    
    public init(base: _opaque_DatabaseRecord) {
        self.base = base
    }
    
    public var id: ID {
        .init(base: base._opaque_id)
    }
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base._opaque_objectWillChange
    }
    
    public var isInitialized: Bool {
        base.isInitialized
    }
    
    public var allReservedKeys: [CodingKey] {
        base.allReservedKeys
    }
    
    public var allKeys: [CodingKey] {
        base.allKeys
    }
    
    public func contains(_ key: CodingKey) -> Bool {
        base.contains(key)
    }
    
    public func containsValue(forKey key: CodingKey) -> Bool {
        base.containsValue(forKey: key)
    }
    
    public func primitivelyEncodeValue<Value: PrimitiveAttributeDataType>(_ value: Value, forKey key: CodingKey) throws {
        try base.primitivelyEncodeValue(value, forKey: key)
    }

    public func unsafeEncodeValue(_ value: Any?, forKey key: CodingKey) throws {
        try base.unsafeEncodeValue(value, forKey: key)
    }
    
    public func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try base.encode(value, forKey: key)
    }
    
    public func unsafeDecodeValue(forKey key: CodingKey) throws -> Any? {
        try base.unsafeDecodeValue(forKey: key)
    }
    
    public func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }

    public func relatedRecords(forKey key: CodingKey) async throws -> [_opaque_DatabaseRecord] {
        try await base.relatedRecords(forKey: key)
    }
    
    public func relationship(for key: CodingKey) throws -> AnyDatabaseRecordRelationship {
        .init(base: try base._opaque_relationship(forKey: key))
    }
}

// MARK: - Supplementary API -

extension Entity {
    public init(from record: AnyDatabaseRecord) throws {
        try self.init(_underlyingDatabaseRecord: record.base)
    }
}

extension AnyDatabaseRecord {
    public convenience init<E: Entity>(from entity: E) throws {
        try self.init(base: entity._underlyingDatabaseRecord.unwrap())
    }
}
