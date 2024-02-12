//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Swallow

extension _Schema.Entity {
    public struct AttributeConfiguration: Codable, Hashable {
        public var type: _SerializedTypeIdentity
        public var attributeType: _Schema.Entity.AttributeType
        public var traits: [EntityAttributeTrait]
        public var defaultValue: AnyCodableOrNSCodingValue?
        
        public func _resolveSwiftType() throws -> Any.Type {
            try (try? type.resolveType()) ?? attributeType._swiftType
        }
    }
    
    public final class Attribute: _Schema.Entity.Property {
        private enum CodingKeys: String, CodingKey {
            case attributeConfiguration
        }
        
        public let attributeConfiguration: AttributeConfiguration
        
        public init(
            name: String,
            propertyConfiguration: PropertyConfiguration,
            attributeConfiguration: AttributeConfiguration
        ) {
            self.attributeConfiguration = attributeConfiguration
            
            super.init(
                type: .attribute,
                name: name,
                propertyConfiguration: propertyConfiguration
            )
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.attributeConfiguration = try container.decode(forKey: .attributeConfiguration)
            
            try super.init(from: decoder)
        }
        
        public override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(attributeConfiguration, forKey: .attributeConfiguration)
        }
        
        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            
            hasher.combine(attributeConfiguration)
        }
    }
}
