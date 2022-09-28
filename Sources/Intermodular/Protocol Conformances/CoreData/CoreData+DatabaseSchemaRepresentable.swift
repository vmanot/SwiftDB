//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swift

extension NSManagedObjectModel: DatabaseSchemaRepresentable {
    public func makeDatabaseSchema(context: Context) throws -> DatabaseSchema {
        fatalError()
    }
}
