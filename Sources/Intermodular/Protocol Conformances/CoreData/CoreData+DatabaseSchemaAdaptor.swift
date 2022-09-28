//
// Copyright (c) Vatsal Manot
//

import Compute
import CoreData
import Merge
import Swallow

extension _CoreData {
    public struct DatabaseSchemaAdaptor: SwiftDB.DatabaseSchemaAdaptor {
        public typealias Database = _CoreData.Database
        
        private let schema: DatabaseSchema
        private let recordTypesByEntityID: BidirectionalMap<DatabaseSchema.Entity.ID, Database.RecordContext.RecordType>
        
        init(schema: DatabaseSchema) {
            self.schema = schema
            
            var recordTypesByEntityID = BidirectionalMap<DatabaseSchema.Entity.ID, Database.RecordContext.RecordType>()
            
            for entity in schema.entities {
                recordTypesByEntityID[entity.id] = Database.RecordContext.RecordType(rawValue: entity.name)
            }
            
            self.recordTypesByEntityID = recordTypesByEntityID
        }
        
        public func recordType(
            for entity: DatabaseSchema.Entity.ID?
        ) throws -> _CoreData.DatabaseRecord.RecordType {
            try recordTypesByEntityID.value(forKey: entity.unwrap()).unwrap()
        }
        
        public func entity(
            forRecordType recordType: _CoreData.DatabaseRecord.RecordType
        ) throws -> DatabaseSchema.Entity.ID? {
            try recordTypesByEntityID.key(forValue: recordType).unwrap()
        }
    }
}

extension _CoreData.DatabaseSchemaAdaptor {
    private enum Error: Swift.Error {
        case defaultRecordTypeUnavailable
    }
}
