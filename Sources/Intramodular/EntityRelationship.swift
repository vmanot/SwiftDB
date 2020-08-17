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
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    
    public var base: NSManagedObject?
    public var name: String?
    
    public var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public let isTransient: Bool = false
    
    let inverse: WritableKeyPath<InverseValueEntity, InverseValue>
    let deleteRule: NSDeleteRule?
    
    var wrappedValue_didSet_hash: AnyHashable?
    
    public var wrappedValue: Value {
        get {
            do {
                return try Value.decode(from: base.unwrap(), forKey: .init(stringValue: name.unwrap()))
            } catch {
                return .init()
            }
        } set {
            defer {
                wrappedValue_didSet_hash = UUID()
            }
            
            if let base = base {
                try! newValue.encode(to: base, forKey: .init(stringValue: name.unwrap()))
            }
        }
    }
    
    public init(inverse: WritableKeyPath<InverseValueEntity, InverseValue>, deleteRule: NSDeleteRule? = nil) {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    public init(inverse: WritableKeyPath<Parent, InverseValue>, deleteRule: NSDeleteRule? = nil) where InverseValueEntity == Parent {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    public init(inverse: WritableKeyPath<InverseValueEntity, InverseValue>, deleteRule: NSDeleteRule? = nil) where Value == InverseValueEntity, ValueEntity == InverseValueEntity {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    public init(inverse: WritableKeyPath<InverseValueEntity, InverseValue>, deleteRule: NSDeleteRule? = nil) where Value == Optional<InverseValueEntity>, Value == Optional<ValueEntity> {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    public init(inverse: WritableKeyPath<Parent, RelatedModels<Parent>>, deleteRule: NSDeleteRule? = nil) where ValueEntity == Value.RelatableEntityType, InverseValue == RelatedModels<Parent>, InverseValueEntity == Parent {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    public init(inverse: WritableKeyPath<Parent, RelatedModels<Parent>?>, deleteRule: NSDeleteRule? = nil) where ValueEntity == Value.RelatableEntityType, InverseValue == Optional<RelatedModels<Parent>>, InverseValueEntity == Parent {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
}

extension EntityRelationship {
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
    
    /// This is a hack to get a `String` representation of the `inverse` key path.
    func _runtime_findInverse() throws -> EntityRelationship<Parent, InverseValue, InverseValueEntity, Value, ValueEntity>? {
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
                    
                    // Profit.
                    return try cast(value, to: <<infer>>)
                }
            }
        }
        
        return nil
    }
}
