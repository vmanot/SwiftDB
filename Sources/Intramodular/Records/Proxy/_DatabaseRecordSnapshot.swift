//
// Copyright (c) Vatsal Manot
//

import Compute
import CorePersistence
import Swallow

final class _DatabaseRecordSnapshot {
    let allKeys: [CodingKey]
    var fieldValues: [AnyCodingKey: Any]
    var fieldValuesDiff = DictionaryDifference<AnyCodingKey, Any>(insertions: [], updates: [], removals: [])

    init(
        from container: _DatabaseRecordContainer
    ) throws {
        self.allKeys = container.allKeys

        var fieldValues = [AnyCodingKey: Any](minimumCapacity: allKeys.count)

        for key in container.allKeys {
            fieldValues[AnyCodingKey(key)] = try container.decodeUnsafeFieldValue(forKey: key)
        }

        self.fieldValues = fieldValues
    }

    deinit {
        if !fieldValuesDiff.isEmpty {
            assertionFailure()
        }
    }
}

extension _DatabaseRecordSnapshot: _DatabaseRecordProxyBase {
    func containsValue(forKey key: CodingKey) throws -> Bool {
        fieldValues.contains(key: AnyCodingKey(key))
    }

    func decode<Value>(_ type: Value.Type, forKey key: CodingKey) throws -> Value {
        return try cast(fieldValues[AnyCodingKey(key)], to: Value.self)
    }

    func encode<Value>(_ value: Value, forKey key: CodingKey) throws {
        try encodeUnsafeFieldValue(value, forKey: key)
    }

    func removeValueOrRelationship(forKey key: CodingKey) throws {
        fieldValues[AnyCodingKey(key)] = nil
        fieldValuesDiff[AnyCodingKey(key)] = nil
    }

    func decodeUnsafeFieldValue(forKey key: CodingKey) throws -> Any? {
        fieldValues[AnyCodingKey(key)]
    }

    func encodeUnsafeFieldValue(_ value: Any?, forKey key: CodingKey) throws {
        fieldValues[AnyCodingKey(key)] = value
        fieldValuesDiff[AnyCodingKey(key)] = value
    }

    func decodeFieldPayload(forKey key: CodingKey) throws -> _RecordFieldPayload? {
        fatalError()
    }

    func primaryKeyOrRecordID() throws -> _PrimaryKeyOrRecordID {
        fatalError()
    }
}
