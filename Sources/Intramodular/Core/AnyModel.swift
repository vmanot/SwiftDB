//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct AnyDatabaseCodableDump {
    public let data: [AnyModel]
}

public struct AnyModel: Codable, Hashable {
    public struct NominalTypeDescriptor: Codable, Hashable, Identifiable {
        public let id: String
    }
    
    public let nominalTypeDescriptor: NominalTypeDescriptor
    public let data: AnyCodable
}
