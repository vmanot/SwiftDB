//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct ModelTypeMetadata: Codable {
    static let codingKey: AnyStringKey = "@metadata"
    
    public let entityName: String?
    public let version: Version?
    
    public init(from modelType: _opaque_Model.Type) {
        self.entityName = (modelType as? _opaque_Entity.Type)?.name
        self.version = modelType.version
    }
}
