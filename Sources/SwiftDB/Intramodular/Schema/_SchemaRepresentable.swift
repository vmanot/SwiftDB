//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

public protocol _SchemaRepresentable {
    typealias Context = Void
    
    func makeSchema(context: Context) throws -> _Schema
}
