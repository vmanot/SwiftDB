//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

public protocol DatabaseSchemaRepresentable {
    typealias Context = Void
    
    func makeDatabaseSchema(context: Context) throws -> DatabaseSchema
}
