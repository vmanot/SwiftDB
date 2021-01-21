//
// Copyright (c) Vatsal Manot
//

import Swallow

struct _EntityRuntimeMetadata: Codable {
    static let codingKey: AnyStringKey = "@metadata"
    
    public let name: String
}

extension Entity where Self: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyStringKey.self)
        let runtime = decoder.userInfo._SwiftDB_runtime
        
        let _runtime_metadata = try container.decode(
            _EntityRuntimeMetadata.self,
            forKey: _EntityRuntimeMetadata.codingKey
        )
        
        let type = runtime.typeCache.entity[_runtime_metadata.name]!.value
        
        self = try decoder.userInfo._SwiftDB_PersistentContainer._opaque_create(type) as! Self
        
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
        
        try container.encode(_EntityRuntimeMetadata(name: Self.name), forKey: _EntityRuntimeMetadata.codingKey)
    }
}
