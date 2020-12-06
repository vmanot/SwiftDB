//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

@usableFromInline
protocol _opaque_EntityRelationshipAccessor: _opaque_PropertyAccessor {
    var wrappedValue_didSet_hash: AnyHashable? { get set }
}

/// A property accessor for entity relationships.
@propertyWrapper
public final class EntityRelationship<
    Parent: Entity & Identifiable,
    Value: EntityRelatable,
    ValueEntity: Entity & Identifiable,
    InverseValue: EntityRelatable,
    InverseValueEntity: Entity & Identifiable
>: _opaque_EntityRelationshipAccessor, PropertyWrapper {
    @usableFromInline
    enum InverseKeyPath {
        case toOne(WritableKeyPath<ValueEntity, InverseValue>)
        case oneToMany(WritableKeyPath<ValueEntity, InverseValue>)
        case manyToMany(WritableKeyPath<ValueEntity, RelatedModels<Parent>>)
    }
    
    @usableFromInline
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    @usableFromInline
    var underlyingObject: DatabaseObject?
    
    @usableFromInline
    var name: String?
    @usableFromInline
    let isTransient: Bool = false
    @usableFromInline
    var renamingIdentifier: String?
    @usableFromInline
    let inverse: InverseKeyPath
    @usableFromInline
    let deleteRule: NSDeleteRule?
    
    @usableFromInline
    var wrappedValue_didSet_hash: AnyHashable?
    
    @usableFromInline
    var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            do {
                return try Value.decode(from: (underlyingObject.unwrap() as! _CoreData.DatabaseObject).base, forKey: .init(stringValue: name.unwrap()))
            } catch {
                return .init(noRelatedModels: ())
            }
        } set {
            defer {
                wrappedValue_didSet_hash = UUID()
            }
            
            if let underlyingObject = underlyingObject {
                try! underlyingObject.encode(newValue, forKey: key.unwrap())
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
}

extension EntityRelationship {
    /// This is a hack to get a `String` representation of the `inverse` key path.
    @usableFromInline
    func _runtime_findInverse() throws -> _opaque_EntityRelationshipAccessor? {
        let emptyInverseEntity: AnyNominalOrTupleMirror
        
        switch inverse {
            case .toOne(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = ValueEntity.init()
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_hash` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
            }
            case .oneToMany(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = destinationEntityType.init() as! ValueEntity
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_hash` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
            }
            case .manyToMany(let inverse): do {
                // Create an empty instance of the inverse entity.
                var subject = Value.RelatableEntityType.init() as! ValueEntity
                
                // "Touch" the inverse key path (by reassigning its value to itself).
                // This sets the `wrappedValue_didSet_hash` for the _one_ relationship accessor representing the inverse.
                subject[keyPath: inverse] = subject[keyPath: inverse]
                
                emptyInverseEntity = AnyNominalOrTupleMirror(subject)!
            }
        }
        
        // Walk through all properties of the empty inverse instance.
        for (key, value) in emptyInverseEntity.children {
            if var value = value as? _opaque_EntityRelationshipAccessor {
                // Find the inverse relationship accessor that was "touched".
                if value.wrappedValue_didSet_hash != nil {
                    if value.name == nil {
                        value.name = .init(key.stringValue.dropPrefixIfPresent("_"))
                    }
                    
                    return value
                }
            }
        }
        
        return nil
    }
    
    public func toEntityPropertyDescription() -> EntityPropertyDescription {
        return EntityRelationshipDescription(
            name: name!,
            isOptional: isOptional,
            isTransient: isTransient,
            renamingIdentifier: renamingIdentifier,
            destinationEntityName: destinationEntityType.name,
            inverseRelationshipName: try! _runtime_findInverse()?.name,
            cardinality: .init(source: InverseValue.entityCardinality, destination: Value.entityCardinality),
            deleteRule: deleteRule
        )
    }
    
    private var destinationEntityType: _opaque_Entity.Type {
        if ValueEntity.isSuperclass(of: Value.RelatableEntityType.self) {
            return Value.RelatableEntityType.self
        } else if Value.RelatableEntityType.isSuperclass(of: ValueEntity.self) {
            return ValueEntity.self
        } else {
            return Value.RelatableEntityType.self
        }
    }
}

extension _opaque_Entity {
    public static func isSuperclass(of other: _opaque_Entity.Type) -> Bool {
        if other == Self.self {
            return false
        } else if other is Self.Type {
            return true
        } else {
            return false
        }
    }
}
extension EntityRelationship {
    @_disfavoredOverload
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == InverseValueEntity, ValueEntity == InverseValueEntity {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    @_disfavoredOverload
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    @_disfavoredOverload
    public convenience init(
        inverse: WritableKeyPath<Parent, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == RelatedModels<ValueEntity>, InverseValue == Optional<Parent>  {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == RelatedModels<InverseValueEntity>, Value == RelatedModels<ValueEntity>, InverseValue == Optional<Parent> {
        self.init(inverse: .toOne(inverse), deleteRule: deleteRule)
    }
}

extension EntityRelationship {
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, InverseValue>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<ValueEntity>, InverseValue == RelatedModels<Parent> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<InverseValueEntity, RelatedModels<Parent>>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == InverseValueEntity, Value == Optional<ValueEntity>, ValueEntity == InverseValueEntity, InverseValue == RelatedModels<Parent> {
        self.init(inverse: .oneToMany(inverse), deleteRule: deleteRule)
    }
    
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<Parent, RelatedModels<Parent>?>,
        deleteRule: NSDeleteRule? = nil
    ) where Parent == ValueEntity, Parent == InverseValueEntity, ValueEntity == Value.RelatableEntityType, InverseValue == Optional<RelatedModels<Parent>> {
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
    @inlinable
    public convenience init(
        inverse: WritableKeyPath<ValueEntity, RelatedModels<Parent>>,
        deleteRule: NSDeleteRule? = nil
    ) where Value == RelatedModels<ValueEntity>, InverseValue == RelatedModels<Parent>, InverseValueEntity == Parent {
        self.init(inverse: .manyToMany(inverse), deleteRule: deleteRule)
    }
}
