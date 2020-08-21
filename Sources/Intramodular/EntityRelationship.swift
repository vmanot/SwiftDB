//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

protocol _opaque_EntityRelationshipAccessor: _opaque_PropertyAccessor {
    var wrappedValue_didSet_hash: AnyHashable? { get set }
}

@propertyWrapper
public final class EntityRelationship<
    Parent: Entity,
    Value: EntityRelatable,
    ValueEntity: Entity,
    InverseValue: EntityRelatable,
    InverseValueEntity: Entity
>: _opaque_EntityRelationshipAccessor, _opaque_PropertyAccessor {
    @usableFromInline
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    
    public var underlyingObject: NSManagedObject?
    public var name: String?
    
    @inlinable
    public var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public let isTransient: Bool = false
    
    @usableFromInline
    enum InverseKeyPath {
        case oneToMany(WritableKeyPath<InverseValueEntity, InverseValue>)
        case manyToMany(WritableKeyPath<ValueEntity, RelatedModels<Parent>>)
    }
    
    @usableFromInline
    let inverse: InverseKeyPath
    
    @usableFromInline
    let deleteRule: NSDeleteRule?
    
    @usableFromInline
    var wrappedValue_didSet_hash: AnyHashable?
    
    @inlinable
    public var wrappedValue: Value {
        get {
            do {
                return try Value.decode(from: underlyingObject.unwrap(), forKey: .init(stringValue: name.unwrap()))
            } catch {
                return .init()
            }
        } set {
            defer {
                wrappedValue_didSet_hash = UUID()
            }
            
            if let underlyingObject = underlyingObject {
                try! newValue.encode(to: underlyingObject, forKey: .init(stringValue: name.unwrap()))
            }
        }
    }
    
    @usableFromInline
    init(
        inverse: InverseKeyPath,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    @usableFromInline
    init(
        _inverse inverse: WritableKeyPath<ValueEntity, RelatedModels<Parent>>,
        _deleteRule deleteRule: NSDeleteRule? = nil
    ) {
        self.inverse = .manyToMany(inverse)
        self.deleteRule = deleteRule
    }
}

extension EntityRelationship {
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where InverseValueEntity == Parent {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == InverseValueEntity, ValueEntity == InverseValueEntity {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @_disfavoredOverload
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @_disfavoredOverload
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, RelatedModels<Parent>>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == Optional<InverseValueEntity>, ValueEntity == Value.RelatableEntityType, InverseValue == RelatedModels<Parent>, InverseValueEntity == Parent {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, RelatedModels<Parent>?>,
        deleteRule: NSDeleteRule? = nil
    ) where ValueEntity == Value.RelatableEntityType, InverseValue == Optional<RelatedModels<Parent>>, InverseValueEntity == Parent {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == RelatedModels<InverseValueEntity>, Value == RelatedModels<ValueEntity> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
}

extension EntityRelationship {
    /// This is a hack to get a `String` representation of the `inverse` key path.
    func _runtime_findInverse() throws -> _opaque_EntityRelationshipAccessor? {
        switch inverse {
            case .oneToMany(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = InverseValue.RelatableEntityType.init() as! InverseValueEntity
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_hash` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                let emptyInverseEntity = NominalMirror(reflecting: subject)
                
                // Walk through all properties of the empty inverse instance.
                for (key, value) in emptyInverseEntity.children {
                    if var value = value as? _opaque_EntityRelationshipAccessor {
                        // Find the inverse relationship accessor that was "touched".
                        if value.wrappedValue_didSet_hash != nil {
                            value.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                            
                            return value
                        }
                    }
                }
            }
            case .manyToMany(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = Value.RelatableEntityType.init() as! ValueEntity
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_hash` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                let emptyInverseEntity = NominalMirror(reflecting: subject)
                
                // Walk through all properties of the empty inverse instance.
                for (key, value) in emptyInverseEntity.children {
                    if var value = value as? _opaque_EntityRelationshipAccessor {
                        // Find the inverse relationship accessor that was "touched".
                        if value.wrappedValue_didSet_hash != nil {
                            value.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                            
                            return value
                        }
                    }
                }
                
                return nil
            }
        }
        
        return nil
    }
    
    public func toEntityPropertyDescription() -> EntityPropertyDescription {
        return EntityRelationshipDescription(
            name: name!,
            isOptional: isOptional,
            isTransient: isTransient,
            destinationEntityName: Value.RelatableEntityType.name,
            inverseRelationshipName: try! _runtime_findInverse()?.name,
            cardinality: .init(source: InverseValue.entityCardinality, destination: Value.entityCardinality),
            deleteRule: deleteRule
        )
    }
}

extension EntityRelationship {
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, RelatedModels<Parent>>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == RelatedModels<ValueEntity>, InverseValue == RelatedModels<Parent>, InverseValueEntity == Parent {
        self.init(inverse: .manyToMany(inverse), deleteRule: deleteRule)
    }
}
