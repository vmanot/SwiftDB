//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct UnsafeRecordMigrationDestination {
    let schemaMappingModel: _SchemaMigrationMapping
    let sourceEntity: _Schema.Entity
    let destinationEntity: _Schema.Entity
    let destination: _DatabaseRecordContainer
    
    init(
        schemaMappingModel: _SchemaMigrationMapping,
        sourceEntity: _Schema.Entity,
        destinationEntity: _Schema.Entity,
        destination: _DatabaseRecordContainer
    ) {
        self.schemaMappingModel = schemaMappingModel
        self.sourceEntity = sourceEntity
        self.destinationEntity = destinationEntity
        self.destination = destination
    }
    
    public subscript(key: String) -> Any? {
        get {
            try! destination.decodeFieldPayload(forKey: AnyStringKey(stringValue: key))
        } nonmutating set {
            try! destination.encodeFieldPayload(newValue, forKey: AnyStringKey(stringValue: key))
        }
    }
    
    public subscript(attribute: _Schema.Entity.Attribute) -> Any? {
        get {
            self[attribute.name]
        } nonmutating set {
            self[attribute.name] = newValue
        }
    }
    
    public struct AttributeEnumerationArguments {
        public let attribute: _Schema.Entity.Attribute
        public let sourceAttribute: _Schema.Entity.Attribute?
    }
    
    /**
     Enumerates the all `NSAttributeDescription`s. The `attribute` argument can be used as the subscript key to access and mutate the property. The `sourceAttribute` can be used to access properties from the source `UnsafeSourceObject`.
     */
    /// Enumerates over all entity attributes.
    public func enumerateAttributes(
        _ body: (AttributeEnumerationArguments) throws -> Void
    ) throws {
        func enumerate(
            _ entity: _Schema.Entity,
            _ body: (AttributeEnumerationArguments) throws -> Void
        ) throws {
            if
                let parentEntityID = entity.parent,
                let parentEntity = schemaMappingModel.destination[parentEntityID]
            {
                try enumerate(parentEntity, body)
            }
            
            for case let attribute as _Schema.Entity.Attribute in entity.properties {
                let sourceAttribute = try self.sourceEntity.properties
                    .first(where: { $0.name == attribute.name })
                    .map({ try cast($0, to: _Schema.Entity.Attribute.self) })
                
                try body(.init(attribute: attribute, sourceAttribute: sourceAttribute))
            }
        }
        
        try enumerate(destinationEntity, body)
    }
}