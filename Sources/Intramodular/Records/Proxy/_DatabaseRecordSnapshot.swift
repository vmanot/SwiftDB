//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Compute
import CorePersistence
import Swallow

final class _DatabaseRecordSnapshot: Loggable {
    let allKeys: [AnyCodingKey]
    var attributeValues: [AnyCodingKey: Any] = [:]
    var relationships: [AnyCodingKey: RelatedDatabaseRecordIdentifiers<AnyDatabase>] = [:]
    
    var attributeValuesDiff = DictionaryDifference<AnyCodingKey, Any>(
        insertions: [],
        updates: [],
        removals: []
    )
    
    init(
        from decoder: _DatabaseRecordDataDecoder
    ) throws {
        self.allKeys = decoder.record.allKeys
        
        try _decodeAllValuesAndRelationships(from: decoder)
    }
    
    private func _decodeAllValuesAndRelationships(
        from decoder: _DatabaseRecordDataDecoder
    ) throws {
        let recordSchema = try cast(decoder.recordSchema.unwrap(), to: _Schema.Entity.self)
        
        for attribute in recordSchema.attributes {
            let key = AnyCodingKey(stringValue: attribute.name)
            
            attributeValues[key] = try decoder.decodeValue(forKey: key)
        }
        
        for relationship in recordSchema.relationships {
            let key = AnyCodingKey(stringValue: relationship.name)
            
            relationships[key] = try decoder.decodeRelationship(forKey: key)
        }
    }
    
    deinit {
        if !attributeValuesDiff.isEmpty {
            assertionFailure()
        }
    }
}

extension _DatabaseRecordSnapshot: _DatabaseRecordProxyBase {
    func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        attributeValues.contains(key: AnyCodingKey(key))
    }
    
    func decodeValue<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value {
        return try cast(decodeValue(forKey: key), to: Value.self)
    }
    
    func encodeValue<Value>(_ value: Value, forKey key: AnyCodingKey) throws {
        try encodeValue(cast(value, to: Optional<Any>.self), forKey: key)
    }
    
    func decodeValue(forKey key: AnyCodingKey) throws -> Any? {
        attributeValues[AnyCodingKey(key)]
    }
    
    func encodeValue(_ value: Any?, forKey key: AnyCodingKey) throws {
        attributeValues[AnyCodingKey(key)] = value
        attributeValuesDiff[AnyCodingKey(key)] = value
    }
    
    func decodeRelationship(
        forKey key: AnyCodingKey
    ) throws -> RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        let relationship = try relationships[key].unwrap()
                
        return relationship
    }
    
    func encodeRelationship(
        _ relationship: RelatedDatabaseRecordIdentifiers<AnyDatabase>,
        forKey key: AnyCodingKey
    ) throws {
        relationships[key] = relationship
    }
    
    func encodeRelationshipDiff(
        _ diff: RelatedDatabaseRecordIdentifiers<AnyDatabase>.Difference,
        forKey key: AnyCodingKey
    ) throws {
        var relationship = try relationships[key].unwrap()
        
        try relationship.applyUnconditionally(diff)
        
        relationships[key] = relationship
    }
}
