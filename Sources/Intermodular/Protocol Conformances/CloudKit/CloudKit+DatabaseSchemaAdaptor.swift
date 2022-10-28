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
            for entity: _Schema.Entity.ID?
        ) throws -> Database.RecordSpace.Record.RecordType {
            fatalError()
        }
        
        public func entity(forRecordType recordType: String) -> _Schema.Entity.ID? {
            fatalError()
        }
    }
}
