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
        
        private let schema: _Schema
        private let recordTypesByEntityID: BidirectionalMap<_Schema.Entity.ID, Database.RecordSpace.RecordType>
        
        init(schema: _Schema) {
            self.schema = schema
            
            var recordTypesByEntityID = BidirectionalMap<_Schema.Entity.ID, Database.RecordSpace.RecordType>()
            
            for entity in schema.entities {
                recordTypesByEntityID[entity.id] = Database.RecordSpace.RecordType(rawValue: entity.name)
            }
            
            self.recordTypesByEntityID = recordTypesByEntityID
        }
        
        public func recordType(
            for entity: _Schema.Entity.ID?
        ) throws -> _CoreData.DatabaseRecord.RecordType {
            try recordTypesByEntityID.value(forKey: entity.unwrap()).unwrap()
        }
        
        public func entity(
            forRecordType recordType: _CoreData.DatabaseRecord.RecordType
        ) throws -> _Schema.Entity.ID? {
            try recordTypesByEntityID.key(forValue: recordType).unwrap()
        }
    }
}

extension _CoreData.DatabaseSchemaAdaptor {
    private enum Error: Swift.Error {
        case defaultRecordTypeUnavailable
    }
}
