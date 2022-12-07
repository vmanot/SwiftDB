//
// Copyright (c) Vatsal Manot
//

import Compute
import CorePersistence
import Swallow

final class _DatabaseRecordSnapshot {
    let allKeys: [AnyCodingKey]
    var fieldValues: [AnyCodingKey: Any]
    var fieldValuesDiff = DictionaryDifference<AnyCodingKey, Any>(insertions: [], updates: [], removals: [])

    init(
        from coder: _DatabaseRecordDataDecoder
    ) throws {
        self.allKeys = coder.record.allKeys

        var fieldValues = [AnyCodingKey: Any](minimumCapacity: allKeys.count)

        for key in allKeys {
            fieldValues[AnyCodingKey(key)] = try coder.unsafeDecodeValue(forKey: key)
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
    func containsValue(forKey key: AnyCodingKey) throws -> Bool {
        fieldValues.contains(key: AnyCodingKey(key))
    }

    func decode<Value>(_ type: Value.Type, forKey key: AnyCodingKey) throws -> Value {
        return try cast(fieldValues[AnyCodingKey(key)], to: Value.self)
    }

    func encode<Value>(_ value: Value, forKey key: AnyCodingKey) throws {
        try unsafeEncodeValue(value, forKey: key)
    }

    func unsafeDecodeValue(forKey key: AnyCodingKey) throws -> Any? {
        fieldValues[AnyCodingKey(key)]
    }

    func unsafeEncodeValue(_ value: Any?, forKey key: AnyCodingKey) throws {
        fieldValues[AnyCodingKey(key)] = value
        fieldValuesDiff[AnyCodingKey(key)] = value
    }
}
