//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit {
    public struct DatabaseSchemaAdaptor: SwiftDB.DatabaseSchemaAdaptor {
        public typealias Database = _CloudKit.Database
        
        public func recordType(
            for entity: DatabaseSchema.Entity.ID?
        ) throws -> _CloudKit.DatabaseRecordContext.RecordType {
           fatalError()
        }
        
        public func entity(forRecordType recordType: String) -> DatabaseSchema.Entity.ID? {
            fatalError()
        }
    }
}
