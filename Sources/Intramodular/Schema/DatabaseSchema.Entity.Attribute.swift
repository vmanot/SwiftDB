//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension DatabaseSchema.Entity {
    public struct AttributeConfiguration: Codable, Hashable {
        public var type: DatabaseSchema.Entity.AttributeType
        public var allowsExternalBinaryDataStorage: Bool
        public var preservesValueInHistoryOnDeletion: Bool
    }
    
    public final class Attribute: DatabaseSchema.Entity.Property {
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
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(attributeConfiguration, forKey: .attributeConfiguration)
        }
        
        public override func hash(into hasher: inout Hasher) {
            super.hash(into: &hasher)
            
            hasher.combine(attributeConfiguration)
        }
    }
}
