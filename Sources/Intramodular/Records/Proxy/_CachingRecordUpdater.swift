//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

final class _CachingRecordUpdater {
    private let recordSchema: _Schema.Record?
    private let record: AnyDatabaseRecord
    private let recordCoder: _DatabaseRecordDataDecoder

    private let onUpdate: (DatabaseRecordUpdate<AnyDatabase>) -> Void

    private var cachedValues: [AnyCodingKey: Any] = [:]
    private var cachedRelationships: [AnyCodingKey: RelatedDatabaseRecordIdentifiers<AnyDatabase>] = [:]
    private var removedValues: Set<AnyCodingKey> = []

    init(
        recordSchema: _Schema.Record?,
        record: AnyDatabaseRecord,
        onUpdate: @escaping (DatabaseRecordUpdate<AnyDatabase>) -> Void
    ) throws {
        self.recordSchema = recordSchema
        self.record = record
        self.recordCoder = try _DatabaseRecordDataDecoder(
            recordSchema: recordSchema,
            record: record
        )
        self.onUpdate = onUpdate
    }

    func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        record.containsValue(forKey: key)
    }

    func decodeValue<T>(_ type: T.Type, forKey key: AnyCodingKey) throws -> T {
        if let existingValue = cachedValues[key] {
            return try cast(existingValue, to: T.self)
        } else {
            let value = try recordCoder.decode(type, forKey: key)

            cachedValues[key] = value

            return value
        }
    }

    func decodeRelationship(
        ofType type: DatabaseRecordRelationshipType,
        forKey key: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        if let cached = cachedRelationships[key] {
            return cached
        } else {
            let relationship = try recordCoder.decodeRelationship(ofType: type, forKey: key)

            cachedRelationships[key] = relationship

            return relationship
        }
    }

    func unsafeDecodeValue(
        forKey key: AnyCodingKey
    ) throws -> Any? {
        if let cached = cachedValues[key] {
            return cached
        } else if let value = try recordCoder.unsafeDecodeValue(forKey: key) {
            cachedValues[key] = value

            return value
        } else {
            return nil
        }
    }

    func unsafeEncodeValue(
        _ newValue: Any?,
        forKey key: AnyCodingKey
    ) {
        cachedValues[key] = newValue

        if let newValue = newValue {
            onUpdate(.init(key: key, payload: .data(.setValue(newValue))))

            removedValues.remove(key)
        } else {
            onUpdate(.init(key: key, payload: .data(.removeValue)))

            removedValues.insert(key)
        }
    }
}
