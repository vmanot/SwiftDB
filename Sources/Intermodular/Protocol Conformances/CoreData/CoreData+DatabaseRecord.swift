//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

extension _CoreData {
    public final class DatabaseRecord: SwiftDB.DatabaseRecord {
        public typealias Database = _CoreData.Database
        
        public lazy var cancellables = Cancellables()
        
        let rawObject: NSManagedObject
        
        init(rawObject: NSManagedObject) {
            self.rawObject = rawObject
        }
    }
}

extension _CoreData.DatabaseRecord {
    public var recordType: _CoreData.DatabaseRecord.RecordType {
        .init(rawValue: rawObject.entity.name!) // FIXME
    }
    
    public var id: ID {
        ID(managedObjectID: rawObject.objectID)
    }
    
    public var allReservedKeys: [AnyCodingKey] {
        []
    }
    
    public var allKeys: [AnyCodingKey] {
        rawObject.entity.attributesByName.map({ AnyCodingKey(stringValue: $0.key) })
    }
    
    public func containsKey(_ key: AnyCodingKey) -> Bool {
        rawObject.entity.attributesByName[key.stringValue] != nil || rawObject.entity.relationshipsByName[key.stringValue] != nil
    }
    
    public func containsValue(forKey key: AnyCodingKey) -> Bool {
        rawObject.primitiveValueExists(forKey: key.stringValue)
    }
    
    public func decode<Value>(
        _ valueType: Value.Type,
        forKey key: AnyCodingKey
    ) throws -> Value {
        if let valueType = valueType as? NSPrimitiveAttributeCoder.Type {
            return try cast(valueType.decode(from: rawObject, forKey: key), to: Value.self)
        } else if let valueType = valueType as? NSAttributeCoder.Type {
            return try cast(valueType.decode(from: rawObject, forKey: key), to: Value.self)
        } else if let valueType = valueType as? Codable.Type {
            return try cast(valueType.decode(from: rawObject, forKey: key), to: Value.self)
        } else {
            throw Error.failedToDecodeValueForKey(key)
        }
    }
    
    public func decodeRelationship(
        ofType type: DatabaseRecordRelationshipType,
        forKey key: AnyCodingKey
    ) throws -> RelatedRecordIdentifiers {
        switch type {
            case .toOne:
                return .toOne(try _toOneRelatedRecordID(forKey: key))
            case .toUnorderedMany:
                return .toUnorderedMany(try _toUnorderedManyRelatedRecordIDs(forKey: key))
            case .toOrderedMany:
                return .toOrderedMany(try _toOrderedManyRelatedRecordIDs(forKey: key))
        }
    }
    
    private func _toOneRelatedRecordID(forKey key: AnyCodingKey) throws -> _CoreData.DatabaseRecord.ID? {
        _CoreData.DatabaseRecord(rawObject: try cast(rawObject._unsafeDecodeValue(forKey: key), to: NSManagedObject.self)).id
    }
    
    private func _toUnorderedManyRelatedRecordIDs(forKey key: AnyCodingKey) throws -> Set<_CoreData.DatabaseRecord.ID> {
        let setOrArray = rawObject._cocoaSetOrArray(forKey: key)
        
        if let setOrArray = setOrArray as? NSSet {
            return Set(try setOrArray.map({ _CoreData.Database.Record(rawObject: try cast($0, to: NSManagedObject.self)).id }))
        } else {
            throw Error.unrecognizedRelationshipContainer(setOrArray, forKey: key)
        }
    }
    
    private func _toOrderedManyRelatedRecordIDs(forKey key: AnyCodingKey) throws -> [_CoreData.DatabaseRecord.ID] {
        let setOrArray = rawObject._cocoaSetOrArray(forKey: key)
        
        if let setOrArray = setOrArray as? NSOrderedSet {
            return try setOrArray.map({ _CoreData.Database.Record(rawObject: try cast($0, to: NSManagedObject.self)).id })
        } else if let setOrArray = setOrArray as? NSArray {
            return try setOrArray.map({ _CoreData.Database.Record(rawObject: try cast($0, to: NSManagedObject.self)).id })
        } else {
            throw Error.unrecognizedRelationshipContainer(setOrArray, forKey: key)
        }
    }
}

// MARK: - Auxiliary

extension _CoreData.DatabaseRecord {
    public struct RecordType: Codable, CustomStringConvertible, Hashable, LosslessStringConvertible {
        public let rawValue: String
        
        public var description: String {
            rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ description: String) {
            self.rawValue = description
        }
    }
    
    public struct ID: Hashable, PredicateExpressionPrimitiveConvertible {
        private let base: NSManagedObjectID
        
        var nsManagedObjectID: NSManagedObjectID {
            base
        }
        
        init(managedObjectID: NSManagedObjectID) {
            self.base = managedObjectID
        }
        
        public func toPredicateExpressionPrimitive() -> PredicateExpressionPrimitive {
            base // FIXME: Is this a valid `NSPredicate` expression primitive?
        }
    }
}

extension _CoreData.Database.Record {
    enum Error: Swift.Error {
        case failedToDecodeValueForKey(AnyCodingKey)
        case attemptedToEncodeRelationshipAsValue(AnyCodingKey)
        case unrecognizedRelationshipContainer(Any, forKey: AnyCodingKey)
    }
}

// MARK: Encoding & Decoding

extension Decodable where Self: Encodable {
    static func decode(from object: NSManagedObject, forKey key: AnyCodingKey) throws -> Self {
        return try _CodableToNSAttributeCoder<Self>.decode(
            from: object,
            forKey: AnyCodingKey(erasing: key)
        )
        .value
    }
    
    func encode(to object: NSManagedObject, forKey key: AnyCodingKey) throws  {
        try _CodableToNSAttributeCoder<Self>(self).encode(
            to: object,
            forKey: AnyCodingKey(erasing: key)
        )
    }
}

extension NSManagedObject {
    func _unsafeDecodeValue(forKey key: AnyCodingKey) throws -> Any? {
        let key = key.stringValue
        
        willAccessValue(forKey: key)
        
        defer {
            didAccessValue(forKey: key)
        }
        
        return primitiveValue(forKey: key)
    }
    
    func _unsafeEncodeValue(_ value: Any?, forKey key: AnyCodingKey) throws  {
        let key = key.stringValue
        
        willChangeValue(forKey: key)
        
        defer {
            didChangeValue(forKey: key)
        }
        
        setPrimitiveValue(value, forKey: key)
    }
    
    func _cocoaSetOrArray(forKey key: AnyCodingKey) -> Any {
        let key = key.stringValue
        let setOrArray: Any
        
        if let value = value(forKey: key) {
            setOrArray = value
        } else {
            setOrArray = NSMutableArray()
            
            setValue(setOrArray, forKey: key)
        }
        
        return setOrArray
    }
    
    func _cocoaMutableSetOrArray(forKey key: AnyCodingKey) -> Any {
        var setOrArray = self._cocoaSetOrArray(forKey: key)
        
        let key = key.stringValue
        
        if setOrArray is NSSet {
            setOrArray = mutableSetValue(forKey: key)
        } else if setOrArray is NSOrderedSet {
            setOrArray = mutableOrderedSetValue(forKey: key)
        } else {
            assertionFailure()
        }
        
        return setOrArray
    }
    
    func _insertRelated(
        objectID: NSManagedObjectID,
        forKey key: AnyCodingKey
    ) throws {
        let rawObjectToInsert = try managedObjectContext.unwrap().object(withPermanentID: objectID)
        let setOrArray = self._cocoaMutableSetOrArray(forKey: key)
        
        if let set = setOrArray as? NSMutableSet {
            set.add(rawObjectToInsert)
        } else if let orderedSet = setOrArray as? NSMutableOrderedSet {
            orderedSet.insert(rawObjectToInsert, at: 0)
        } else if let array = setOrArray as? NSMutableArray {
            array.insert(rawObjectToInsert)
        } else {
            throw _CoreData.Database.Record.Error.unrecognizedRelationshipContainer(setOrArray, forKey: key)
        }
    }
    
    func _removeRelated(
        objectID: NSManagedObjectID,
        forKey key: AnyCodingKey
    ) throws {
        let rawObjectToRemove = try managedObjectContext.unwrap().object(withPermanentID: objectID)
        let setOrArray = self._cocoaMutableSetOrArray(forKey: key)
        
        if let set = setOrArray as? NSMutableSet {
            set.remove(rawObjectToRemove)
        } else if let orderedSet = setOrArray as? NSMutableOrderedSet {
            orderedSet.remove(rawObjectToRemove)
        } else if let array = setOrArray as? NSMutableArray {
            array.remove(rawObjectToRemove)
        } else {
            throw _CoreData.Database.Record.Error.unrecognizedRelationshipContainer(setOrArray, forKey: key)
        }
    }
    
    func _setToOne(
        _ objectID: NSManagedObjectID?,
        forKey key: AnyCodingKey
    ) throws {
        if let objectID = objectID {
            let rawObjectToSet = try managedObjectContext.unwrap().object(withPermanentID: objectID)
            
            try _unsafeEncodeValue(rawObjectToSet, forKey: key)
        } else {
            try _unsafeEncodeValue(nil, forKey: key)
        }
    }
    
    func _setToUnorderedMany(
        _ objectIDs: Set<NSManagedObjectID>,
        forKey key: AnyCodingKey
    ) throws {
        let managedObjectsToSet = try objectIDs.map({ try managedObjectContext.unwrap().object(withPermanentID: $0) })
        
        setValue(NSMutableSet(array: managedObjectsToSet), forKey: key.stringValue)
    }
    
    func _setToOrderedMany(
        _ objectIDs: [NSManagedObjectID],
        forKey key: AnyCodingKey
    ) throws {
        let managedObjectsToSet = try objectIDs.map({ try managedObjectContext.unwrap().object(withPermanentID: $0) })
        
        setValue(NSMutableArray(array: managedObjectsToSet), forKey: key.stringValue)
    }
    
    func _applyToUnorderedManyDiff(
        _ diff: Set<NSManagedObjectID>.Difference,
        forKey key: AnyCodingKey
    ) throws {
        let managedObjectContext = try self.managedObjectContext.unwrap()
        
        var set = try cast(self._cocoaMutableSetOrArray(forKey: key), to: Set<NSManagedObject>.self)
        
        set.applyUnconditionally(diff.map({ managedObjectContext.object(with: $0) })) // TODO: Validate existence of objects
        
        setValue(set, forKey: key.stringValue)
    }
    
    func _applyToOrderedManyDiff(
        _ diff: Array<NSManagedObjectID>.Difference,
        forKey key: AnyCodingKey
    ) throws {
        let managedObjectContext = try self.managedObjectContext.unwrap()
        
        let setOrArray = self._cocoaMutableSetOrArray(forKey: key)
        
        if setOrArray is NSOrderedSet {
            var array = try cast(self._cocoaMutableSetOrArray(forKey: key), to: NSOrderedSet.self).map({ try cast($0, to: NSManagedObject.self) })
            
            try array.applyUnconditionally(diff.map({ managedObjectContext.object(with: $0) }))
            
            setValue(NSOrderedSet(array: array), forKey: key.stringValue)
        } else if setOrArray is NSArray {
            var array = try cast(self._cocoaMutableSetOrArray(forKey: key), to: Array<NSManagedObject>.self)
            
            try array.applyUnconditionally(diff.map({ managedObjectContext.object(with: $0) }))
            
            setValue(array, forKey: key.stringValue)
        } else {
            throw _CoreData.Database.Record.Error.unrecognizedRelationshipContainer(setOrArray, forKey: key)
        }
    }
}
