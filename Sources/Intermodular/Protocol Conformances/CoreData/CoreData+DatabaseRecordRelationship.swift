//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.DatabaseRecord {
    public struct Relationship: DatabaseRecordRelationship {
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
        
        public func insert(_ record: Record) throws {
            let setOrArray = self.mutableSetOrArray()
            
            if let set = setOrArray as? NSMutableSet {
                set.add(record.rawObject)
            } else if let orderedSet = setOrArray as? NSMutableOrderedSet {
                orderedSet.insert(record.rawObject, at: 0)
            } else if let array = setOrArray as? NSMutableArray {
                array.insert(record.rawObject)
            } else {
                throw Error.unrecognizedRelationshipContainer(setOrArray)
            }
                        
            record.objectWillChange.send()
        }
        
        public func remove(_ record: Record) throws {
            let setOrArray = self.mutableSetOrArray()
            
            if let set = setOrArray as? NSMutableSet {
                set.remove(record.rawObject)
            } else if let orderedSet = setOrArray as? NSMutableOrderedSet {
                orderedSet.remove(record.rawObject)
            } else if let array = setOrArray as? NSMutableArray {
                array.remove(record.rawObject)
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
