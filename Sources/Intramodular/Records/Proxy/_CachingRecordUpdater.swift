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
}

extension _CachingRecordUpdater {
    func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        record.containsValue(forKey: key)
    }
        
    func encodeInitialValue<T>(
        _ newValue: T,
        forKey key: AnyCodingKey
    ) throws {
        if let newValue = try cast(newValue, to: Optional<Any>.self) {
            cachedValues[key] = newValue
            removedValues.remove(key)
            
            onUpdate(.init(key: key, payload: .data(.setValue(newValue))))
        } else {
            // TODO: Handle `nil` initial values?
        }
    }
    
    func encodeValue(
        _ newValue: Any?,
        forKey key: AnyCodingKey
    ) throws {
        if let newValue = newValue {
            cachedValues[key] = newValue
            removedValues.remove(key)
            
            onUpdate(.init(key: key, payload: .data(.setValue(newValue))))
        } else {
            cachedValues[key] = nil
            removedValues.insert(key)
            
            onUpdate(.init(key: key, payload: .data(.removeValue)))
        }
    }
    
    func decodeValue<T>(_ type: T.Type, forKey key: AnyCodingKey) throws -> T {
        if let existingValue = cachedValues[key] {
            return try cast(existingValue, to: T.self)
        } else {
            let value = try recordCoder.decodeValue(type, forKey: key)
            
            cachedValues[key] = value
            
            return value
        }
    }
    
    func decodeValue(
        forKey key: AnyCodingKey
    ) throws -> Any? {
        if let cached = cachedValues[key] {
            return cached
        } else if let value = try recordCoder.decodeValue(forKey: key) {
            cachedValues[key] = value
            
            return value
        } else {
            return nil
        }
    }

    func decodeRelationship(
        forKey key: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        if let cached = cachedRelationships[key] {
            return cached
        } else {
            let relationship = try recordCoder.decodeRelationship(forKey: key)
            
            cachedRelationships[key] = relationship
            
            return relationship
        }
    }
    
    func encodeRelationship(
        _ relationship: RelatedDatabaseRecordIdentifiers<AnyDatabase>,
        forKey key: AnyCodingKey
    ) throws {
        cachedRelationships[key] = relationship
        
        onUpdate(.init(key: key, payload: .relationship(.set(relationship))))
    }
    
    func encodeRelationshipDiff(
        diff: RelatedDatabaseRecordIdentifiers<AnyDatabase>.Difference,
        forKey key: AnyCodingKey
    ) throws {
        var relationship = try decodeRelationship(forKey: key)
        
        try relationship.applyUnconditionally(diff)
        
        cachedRelationships[key] = relationship
        
        onUpdate(.init(key: key, payload: .relationship(.apply(difference: diff))))
    }
}
