//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.DatabaseRecord {
    public struct Relationship: DatabaseRecordRelationship {
        public typealias Record = _CoreData.DatabaseRecord
        
        let record: Record
        let key: CodingKey
        
        public func toOneRelationship() throws -> any ToOneDatabaseRecordRelationship<Record> {
            ToOneRelationship(record: record, key: key)
        }
        
        public func toManyRelationship() throws -> any ToManyDatabaseRecordRelationship<Record> {
            ToManyRelationship(record: record, key: key)
        }
    }
}

extension _CoreData.DatabaseRecord {
    public struct ToOneRelationship: ToOneDatabaseRecordRelationship {
        public typealias Record = _CoreData.DatabaseRecord
        
        let record: Record
        let key: CodingKey
        
        public func getRecord() throws -> _CoreData.DatabaseRecord.ID? {
            _CoreData.DatabaseRecord(rawObject: try cast(record.unsafeDecodeValue(forKey: key), to: NSManagedObject.self)).id
        }
        
        public func setRecord(_ otherRecordID: Record.ID?) throws {
            if let otherRecordID = otherRecordID {
                let rawObjectToSet = try record.rawObject.managedObjectContext.unwrap().object(withPermanentID: otherRecordID.nsManagedObjectID)
                
                try record.unsafeEncodeValue(rawObjectToSet, forKey: key)
            } else {
                try record.unsafeEncodeValue(nil, forKey: key)
            }
        }
    }
}

extension _CoreData.DatabaseRecord {
    public struct ToManyRelationship: ToManyDatabaseRecordRelationship {
        public enum Error: Swift.Error {
            case unrecognizedRelationshipContainer(Any)
        }
        
        public typealias Record = _CoreData.DatabaseRecord
        
        private let record: Record
        private let key: CodingKey
        
        init(record: Record, key: CodingKey) {
            self.record = record
            self.key = key
        }
        
        private func setOrArray() -> Any {
            let key = key.stringValue
            let setOrArray: Any
            
            if let value = record.rawObject.value(forKey: key) {
                setOrArray = value
            } else {
                setOrArray = NSMutableArray()
                
                record.rawObject.setValue(setOrArray, forKey: key)
            }
            
            return setOrArray
        }
        
        private func mutableSetOrArray() -> Any {
            let key = key.stringValue
            
            var setOrArray = self.setOrArray()
            
            if setOrArray is NSSet {
                setOrArray = record.rawObject.mutableSetValue(forKey: key)
            } else if setOrArray is NSOrderedSet {
                setOrArray = record.rawObject.mutableOrderedSetValue(forKey: key)
            }
            
            return setOrArray
        }
        
        public func insert(_ otherRecordID: Record.ID) throws {
            let rawObjectToInsert = try record.rawObject.managedObjectContext.unwrap().object(withPermanentID: otherRecordID.nsManagedObjectID)
            let setOrArray = self.mutableSetOrArray()
            
            if let set = setOrArray as? NSMutableSet {
                set.add(rawObjectToInsert)
            } else if let orderedSet = setOrArray as? NSMutableOrderedSet {
                orderedSet.insert(rawObjectToInsert, at: 0)
            } else if let array = setOrArray as? NSMutableArray {
                array.insert(rawObjectToInsert)
            } else {
                throw Error.unrecognizedRelationshipContainer(setOrArray)
            }
            
            record.objectWillChange.send()
        }
        
        public func remove(_ otherRecordID: Record.ID) throws {
            let rawObjectToRemove = try record.rawObject.managedObjectContext.unwrap().object(withPermanentID: otherRecordID.nsManagedObjectID)
            let setOrArray = self.mutableSetOrArray()
            
            if let set = setOrArray as? NSMutableSet {
                set.remove(rawObjectToRemove)
            } else if let orderedSet = setOrArray as? NSMutableOrderedSet {
                orderedSet.remove(rawObjectToRemove)
            } else if let array = setOrArray as? NSMutableArray {
                array.remove(rawObjectToRemove)
            } else {
                throw Error.unrecognizedRelationshipContainer(setOrArray)
            }
            
            record.objectWillChange.send()
        }
        
        public func all() throws -> [Record] {
            let setOrArray = self.setOrArray()
            
            if let setOrArray = setOrArray as? NSSet {
                return try setOrArray.map({ Record(rawObject: try cast($0, to: NSManagedObject.self)) })
            } else if let setOrArray = setOrArray as? NSOrderedSet {
                return try setOrArray.map({ Record(rawObject: try cast($0, to: NSManagedObject.self)) })
            } else if let setOrArray = setOrArray as? NSArray {
                return try setOrArray.map({ Record(rawObject: try cast($0, to: NSManagedObject.self)) })
            } else {
                throw Error.unrecognizedRelationshipContainer(setOrArray)
            }
        }
    }
}
