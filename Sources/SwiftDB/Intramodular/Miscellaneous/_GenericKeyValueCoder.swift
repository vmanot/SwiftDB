//
// Copyright (c) Vatsal Manot
//

import Swallow

protocol _GenericKeyValueCoder {
    func decode<Key: CodingKey, Value: Encodable>(_ type: Value.Type, forKey key: Key) throws -> Value
    func encode<Key: CodingKey, Value: Decodable>(_ value: Value, forKey key: Key) throws
    func remove<Key: CodingKey, Value: Decodable>(_ type: Value.Type, forKey key: Key) throws -> Value
}
