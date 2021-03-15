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

extension NSManagedObject {
    var _SwiftDB_databaseSchema: DatabaseSchema? {
        managedObjectContext?.persistentStoreCoordinator?._SwiftDB_databaseSchema
    }
}
