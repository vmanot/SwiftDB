//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

public struct _SchemaHistory: Codable, Hashable, Sendable {
    @LossyCoding
    public var schemas: [_Schema] = []
    
    public init() {
        
    }
}
