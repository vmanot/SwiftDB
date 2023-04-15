//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct _SchemaHistory: Codable, Hashable, Sendable {
    @LossyCoding
    public var schemas: [_Schema] = []
    
    public init() {
        
    }
}
