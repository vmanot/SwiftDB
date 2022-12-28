//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A property accessor for entity relationships.
@propertyWrapper
public final class EntityRelationship<
    Value: _EntityRelationshipDestination
>: _EntityPropertyAccessor, EntityPropertyAccessor, ObservableObject, PropertyWrapper {
    public typealias _RelationshipDestination = Value
    
    enum InverseKeyPath {
        case oneToOne(AnyKeyPath)
        case oneToMany(AnyKeyPath)
        case manyToOne(AnyKeyPath)
        case manyToMany(AnyKeyPath)
        
        var cardinality: _Schema.Entity.Relationship.Cardinality {
            switch self {
                case .oneToOne:
                    return .oneToOne
                case .oneToMany:
                    return .oneToMany
                case .manyToOne:
                    return .manyToOne
                case .manyToMany:
                    return .manyToMany
            }
        }
        
        var keyPath: AnyKeyPath {
            switch self {
                case .oneToOne(let keyPath):
                    return keyPath
                case .oneToMany(let keyPath):
                    return keyPath
                case .manyToOne(let keyPath):
                    return keyPath
                case .manyToMany(let keyPath):
                    return keyPath
            }
        }
    }
    
    var _underlyingRecordProxy: _DatabaseRecordProxy?
    var _runtimeMetadata = _EntityPropertyAccessorRuntimeMetadata(valueType: Value.self)
    
    public var name: String?
    
    private let inverse: InverseKeyPath
    private let deleteRule: NSDeleteRule?
    private let traits: [EntityRelationshipTrait]
    
    var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            _runtimeMetadata.didAccessWrappedValueGetter = true
            
            return try! .init(_relationshipPropertyAccessor: self)
        }
    }
    
    public var projectedValue: EntityRelationship {
        self
    }
    
    private init(
        inverse: InverseKeyPath,
        deleteRule: NSDeleteRule? = nil,
        traits: [EntityRelationshipTrait]
    ) {
        self.inverse = inverse
        self.deleteRule = deleteRule
        self.traits = traits
    }
    
    func initialize(with container: _DatabaseRecordProxy) {
        self._underlyingRecordProxy = container
    }
}

extension EntityRelationship where Value: _EntityRelationshipToManyDestination {
    public convenience init<Inverse: _EntityRelationshipToOneDestination>(
        inverse: KeyPath<Value._DestinationEntityType, Inverse>,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(inverse: .manyToOne(inverse), deleteRule: deleteRule, traits: [])
    }
}

extension EntityRelationship where Value: _EntityRelationshipToOneDestination {
    public convenience init<Inverse: _EntityRelationshipToOneDestination>(
        inverse: KeyPath<Value._DestinationEntityType, Inverse>,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(inverse: .oneToOne(inverse), deleteRule: deleteRule, traits: [])
    }
    
    public convenience init<Inverse: _EntityRelationshipToManyDestination>(
        inverse: KeyPath<Value._DestinationEntityType, Inverse>,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule, traits: [])
    }
}

extension EntityRelationship {
    private var destinationEntityType: any Entity.Type {
        Value._destinationEntityType
    }
    
    /// This is a hack to get a `String` representation of the `inverse` key path.
    func _runtime_findInverse() throws -> (any _EntityPropertyAccessor)? {
        // Create an empty instance of the inverse entity.
        let subject = Value._destinationEntityType.init()
        
        // "Touch" the inverse key path by evaluating it.
        // This sets the `_runtimeMetadata.didAccessWrappedValueGetter` to true for the _one_ relationship accessor representing the inverse.
        _ = subject[keyPath: inverse.keyPath]
        
        let emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
        
        // Walk through all properties of the empty inverse instance.
        for (key, value) in emptyInverseEntity.children {
            if let value = value as? any _EntityPropertyAccessor {
                // Find the inverse relationship accessor that was "touched".
                if value._runtimeMetadata.didAccessWrappedValueGetter == true {
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
        var relationshipConfiguration = _Schema.Entity.RelationshipConfiguration(
            traits: traits,
            destinationEntity: try! _Schema.Entity.ID(from: destinationEntityType),
            inverseRelationshipName: nil,
            cardinality: inverse.cardinality.inverse,
            deleteRule: nil,
            isOrdered: true
        )
        
        relationshipConfiguration.inverseRelationshipName = try! _runtime_findInverse()?.name
        
        return _Schema.Entity.Relationship(
            name: name!,
            propertyConfiguration: .init(isOptional: true),
            relationshipConfiguration: relationshipConfiguration
        )
    }
}

extension EntityRelationship {
    private enum _Error: _SwiftDB_Error {
        case getterInaccessible
    }
}
