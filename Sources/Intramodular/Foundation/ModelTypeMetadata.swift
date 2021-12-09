//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct ModelTypeMetadata: Codable {
    public static let codingKey: AnyStringKey = "@metadata"

    public let entityName: String?
    public let version: Version?

    public init(from modelType: Model.Type) {
        self.entityName = (modelType as? _opaque_Entity.Type)?.name
        self.version = modelType.version
    }
}
