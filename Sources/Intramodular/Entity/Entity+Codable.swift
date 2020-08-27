//
// Copyright (c) Vatsal Manot
//

import Swallow

extension Entity where Self: Codable {
    public init(from decoder: Decoder) throws {
        self.init(_runtime_underlyingObject: nil)
        
        let container = try decoder.container(keyedBy: AnyStringKey.self)
        
        for property in _runtime_propertyAccessors {
            let decoder = try container.decode(DecoderUnwrapper.self, forKey: property.key.unwrap()).value
            
            try property.decode(from: decoder)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyStringKey.self)
        
        for property in _runtime_propertyAccessors {
            try container.encode(EncodableImpl(property.encode(to:)), forKey: property.key.unwrap())
        }
    }
}
