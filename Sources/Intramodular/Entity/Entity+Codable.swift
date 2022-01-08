//
// Copyright (c) Vatsal Manot
//

import Swallow

extension Entity where Self: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyStringKey.self)
        let metadata = try container.decode(_EntityRuntimeMetadata.self, forKey: _EntityRuntimeMetadata.codingKey)
        
        guard let runtime = decoder.userInfo._SwiftDB_runtime else {
            throw _EntityDecodingError.databaseRuntimeMissing
        }
        
        guard let type = try (runtime.metatype(forEntityNamed: metadata.name)?.value).map({ try cast($0, to: Self.Type.self) }) else {
            throw _EntityDecodingError.couldNotResolveEntityMetatype(forName: metadata.name)
        }
        
        self = try decoder.userInfo._SwiftDB_PersistentContainer.mainContext.create(type)
        
        for property in _runtime_propertyAccessors {
            try property.decode(from: try container.decoder(forKey: property.key.unwrap()))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyStringKey.self)
        
        try container.encode(_EntityRuntimeMetadata(name: Self.name), forKey: _EntityRuntimeMetadata.codingKey)
        
        for property in _runtime_propertyAccessors {
            try container.encode(using: property.encode(to:), forKey: property.key.unwrap())
        }
    }
}

// MARK: - Auxiliary Implementation -

struct _EntityRuntimeMetadata: Codable {
    static let codingKey: AnyStringKey = "@metadata"
    
    public let name: String
}

enum _EntityDecodingError: CustomDebugStringConvertible, Error {
    case databaseRuntimeMissing
    case couldNotResolveEntityMetatype(forName: String)
    
    var debugDescription: String {
        switch self {
            case .databaseRuntimeMissing:
                return "Decoder user info does not have a valid SwiftDB runtime reference"
            case .couldNotResolveEntityMetatype(let name):
                return "Failed to resolve a SwiftDB entity metatype for entity named \"\(name)\""
        }
    }
}
