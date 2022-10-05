//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A property accessor for entity relationships.
@propertyWrapper
public final class EntityRelationship<
    Parent: Entity & Identifiable,
    Value: EntityRelatable,
    ValueEntity: Entity & Identifiable,
    InverseValue: EntityRelatable,
    InverseValueEntity: Entity & Identifiable
>: EntityPropertyAccessor, ObservableObject, PropertyWrapper {
    enum InverseKeyPath {
        case toOne(WritableKeyPath<ValueEntity, InverseValue>)
        case oneToMany(WritableKeyPath<ValueEntity, InverseValue>)
        case manyToMany(WritableKeyPath<ValueEntity, RelatedModels<Parent>>)
        
        var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
            switch self {
                case .toOne:
                    return .one
                case .oneToMany:
                    return .many
                case .manyToMany:
                    return .many
            }
        }
    }
    
    public var _underlyingRecordContainer: _AnyDatabaseRecordContainer?
    
    public var name: String?
    public var propertyConfiguration: _Schema.Entity.PropertyConfiguration = .init(isOptional: true)
    public var relationshipConfiguration: _Schema.Entity.RelationshipConfiguration
    
    let inverse: InverseKeyPath
    let deleteRule: NSDeleteRule?
    
    public var _runtimeMetadata = _opaque_EntityPropertyAccessorRuntimeMetadata(valueType: Value.self)
    
    var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    var isInitialized: Bool {
        _underlyingRecordContainer != nil
    }
    
    public var wrappedValue: Value {
        get {
            _runtimeMetadata.wrappedValueAccessToken = UUID()

            guard isInitialized else {
                return .init(noRelatedModels: ())
            }
            
            return try! _underlyingRecordContainer.unwrap().decode(Value.self, forKey: key)
        } set {
            defer {
                _runtimeMetadata.wrappedValue_didSet_token = UUID()
            }
            
            if let container = _underlyingRecordContainer {
                try! container.encode(newValue, forKey: key)
            }
        }
    }
    
    init(
        inverse: InverseKeyPath,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.inverse = inverse
        self.deleteRule = deleteRule
        
        self.relationshipConfiguration = _Schema.Entity.RelationshipConfiguration(
            destinationEntity: try! _Schema.Entity.ID(from: ValueEntity.self),
            inverseRelationshipName: nil,
            cardinality: .init(
                source: inverse.entityCardinality,
                destination: Value.entityCardinality
            ),
            deleteRule: nil,
            isOrdered: true
        )
    }
    
    public func initialize(with container: _AnyDatabaseRecordContainer) {
        self._underlyingRecordContainer = container
    }
}

extension EntityRelationship {
    private var destinationEntityType: _opaque_Entity.Type {
        if ValueEntity.isSuperclass(of: Value.RelatableEntityType.self) {
            return Value.RelatableEntityType.self
        } else if Value.RelatableEntityType.isSuperclass(of: ValueEntity.self) {
            return ValueEntity.self
        } else {
            return Value.RelatableEntityType.self
        }
    }
    
    /// This is a hack to get a `String` representation of the `inverse` key path.
    func _runtime_findInverse() throws -> (any EntityPropertyAccessor)? {
        let emptyInverseEntity: AnyNominalOrTupleMirror
        
        switch inverse {
            case .toOne(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = ValueEntity.init()
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_token` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
            }
            case .oneToMany(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = destinationEntityType.init() as! ValueEntity
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_token` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
            }
            case .manyToMany(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = Value.RelatableEntityType.init() as! ValueEntity
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_token` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
            }
        }
        
        // Walk through all properties of the empty inverse instance.
        for (key, value) in emptyInverseEntity.children {
            if let value = value as? any EntityPropertyAccessor {
                // Find the inverse relationship accessor that was "touched".
                if value._runtimeMetadata.wrappedValue_didSet_token != nil {
                    if value.name == nil {
                        value.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                    }
                    
                    return value
                }
            }
        }
        
        return nil
    }
    
    public func schema() -> _Schema.Entity.Property {
        var relationshipConfiguration = self.relationshipConfiguration
        
        relationshipConfiguration.inverseRelationshipName = try! _runtime_findInverse()?.name

        return _Schema.Entity.Relationship(
            name: name!,
            propertyConfiguration: propertyConfiguration,
            relationshipConfiguration: relationshipConfiguration
        )
    }
}

extension EntityRelationship {
    @_disfavoredOverload
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == InverseValueEntity, ValueEntity == InverseValueEntity {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    @_disfavoredOverload
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    @_disfavoredOverload
    public convenience init(
        inverse: WritableKeyPath<Parent, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == RelatedModels<ValueEntity>, InverseValue == Optional<Parent>  {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    /*public convenience init(
     inverse: WritableKeyPath<Parent, InverseValue>,
     deleteRule: NSDeleteRule? = nil
     ) where Parent == InverseValueEntity, Value == RelatedModels<InverseValueEntity>, Value == RelatedModels<ValueEntity>, InverseValue == Optional<Parent> {
     self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
     }*/
}

extension EntityRelationship {
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<ValueEntity>, InverseValue == RelatedModels<Parent> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, RelatedModels<Parent>>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<ValueEntity>, ValueEntity == InverseValueEntity, InverseValue == RelatedModels<Parent> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    public convenience init(
        inverse: WritableKeyPath<Parent, RelatedModels<Parent>?>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == ValueEntity, Parent == InverseValueEntity, ValueEntity == Value.RelatableEntityType, InverseValue == Optional<RelatedModels<Parent>> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    /*public convenience init(
     inverse: WritableKeyPath<Parent, InverseValue>,
     deleteRule: NSDeleteRule? = nil
     ) where Parent == InverseValueEntity, Value == RelatedModels<InverseValueEntity>, Value == RelatedModels<ValueEntity> {
     self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
     }*/
}

extension EntityRelationship {
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, RelatedModels<Parent>>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == RelatedModels<ValueEntity>, InverseValue == RelatedModels<Parent>, InverseValueEntity == Parent {
        self.init(inverse: .manyToMany(inverse), deleteRule: deleteRule)
    }
}
