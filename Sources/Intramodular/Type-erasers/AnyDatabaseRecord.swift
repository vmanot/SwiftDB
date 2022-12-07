//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public final class AnyDatabaseRecord: DatabaseRecord, Identifiable, ObservableObject {
    public typealias Database = AnyDatabase

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

    public var recordType: RecordType {
        .init(erasing: base.recordType)
    }

    public var allReservedKeys: [AnyCodingKey] {
        base.allReservedKeys
    }

    public var allKeys: [AnyCodingKey] {
        base.allKeys
    }

    public func containsKey(_ key: AnyCodingKey) throws -> Bool {
        try base.containsKey(key)
    }

    public func containsValue(forKey key: AnyCodingKey) -> Bool {
        base.containsValue(forKey: key)
    }

    public func decode<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value {
        try base.decode(type, forKey: key)
    }

    public func decodeRelationship(
        ofType type: DatabaseRecordRelationshipType,
        forKey key: AnyCodingKey
    ) throws -> RelatedRecordIdentifiers {
        try base._opaque_decodeRelationship(ofType: type, forKey: key)
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

    func _opaque_decodeRelationship(
        ofType type: DatabaseRecordRelationshipType,
        forKey key: AnyCodingKey
    ) throws -> AnyDatabaseRecord.RelatedRecordIdentifiers {
        try .init(erasing: try decodeRelationship(ofType: type, forKey: key))
    }
}
