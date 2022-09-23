//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct UnsafeRecordMigrationDestination {
    let sourceEntity: DatabaseSchema.Entity
    let destinationEntity: DatabaseSchema.Entity
    let destination: AnyDatabaseRecord
    
    init(
        sourceEntity: DatabaseSchema.Entity,
        destinationEntity: DatabaseSchema.Entity,
        destination: AnyDatabaseRecord
    ) {
        self.sourceEntity = sourceEntity
        self.destinationEntity = destinationEntity
        self.destination = destination
    }
    
    public subscript(key: String) -> Any? {
        get {
            try! destination.unsafeDecodeValue(forKey: AnyStringKey(stringValue: key))
        } nonmutating set {
            try! destination.unsafeEncodeValue(newValue, forKey: AnyStringKey(stringValue: key))
        }
    }
    
    public subscript(attribute: DatabaseSchema.Entity.Attribute) -> Any? {
        get {
            self[attribute.name]
        } nonmutating set {
            self[attribute.name] = newValue
        }
    }
    
    /**
     Enumerates the all `NSAttributeDescription`s. The `attribute` argument can be used as the subscript key to access and mutate the property. The `sourceAttribute` can be used to access properties from the source `UnsafeSourceObject`.
     */
    public func enumerateAttributes(
        _ closure: (_ attribute: DatabaseSchema.Entity.Attribute, _ sourceAttribute: DatabaseSchema.Entity.Attribute?) throws -> Void
    ) throws {
        func enumerate(
            _ entity: DatabaseSchema.Entity,
            _ closure: (_ attribute: DatabaseSchema.Entity.Attribute, _ sourceAttribute: DatabaseSchema.Entity.Attribute?) throws -> Void
        ) throws {
            if let superEntity = entity.parent {
                try enumerate(superEntity, closure)
            }
            
            for case let attribute as DatabaseSchema.Entity.Attribute in entity.properties {
                let sourceAttribute = try self.sourceEntity.properties.first(where: { $0.name == attribute.name }).map({ try cast($0, to: DatabaseSchema.Entity.Attribute.self) })
                
                try closure(attribute, sourceAttribute)
            }
        }
        
        try enumerate(destinationEntity, closure)
    }
}
