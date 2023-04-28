//
// Copyright (c) Vatsal Manot
//

import Swallow

extension _Schema {
    public class Record: Codable, Hashable, PolymorphicDecodable, @unchecked Sendable {
        private enum CodingKeys: String, CodingKey {
            case type
            case name
        }
        
        public var type: RecordType
        public var name: String
        
        public var instanceType: RecordType {
            type
        }

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

// MARK: - Conformances

extension _Schema.Record: TypeDiscriminable {
    public enum RecordType: String, Codable, TypeDiscriminator {
        case entity
        
        public func resolveType() -> Any.Type {
            switch self {
                case .entity:
                    return _Schema.Entity.self
            }
        }
    }
}
