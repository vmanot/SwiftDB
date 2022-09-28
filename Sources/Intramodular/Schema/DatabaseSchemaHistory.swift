//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

public struct DatabaseSchemaHistory: Codable, Hashable, Sendable {
    @LossyCoding
    public var schemas: [DatabaseSchema] = []
    
    public init() {
        
    }
}
