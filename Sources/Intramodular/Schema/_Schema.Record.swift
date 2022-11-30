//
// Copyright (c) Vatsal Manot
//

import Swallow

extension _Schema {
    public class Record: Codable, Hashable, @unchecked Sendable {
        private enum CodingKeys: String, CodingKey {
            case type
            case name
        }

        public var type: RecordType
        public var name: String

        public init(type: RecordType, name: String) {
            self.type = type
            self.name = name
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.type = try container.decode(forKey: .type)
            self.name = try container.decode(forKey: .name)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(type, forKey: .type)
            try container.encode(name, forKey: .name)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(name)
        }

        public static func == (lhs: Record, rhs: Record) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}

extension _Schema.Record: PolymorphicDecodable {
    public typealias TypeDiscriminator = RecordType

    public enum RecordType: Codable, CodingTypeDiscriminator {
        case entity

        public var typeValue: Decodable.Type {
            switch self {
                case .entity:
                    return _Schema.Entity.self
            }
        }
    }

    public static func decodeTypeDiscriminator(from decoder: Decoder) throws -> TypeDiscriminator {
        try decoder.container(keyedBy: CodingKeys.self).decode(forKey: .type)
    }
}
