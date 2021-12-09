//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

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
>: _opaque_EntityRelationshipAccessor, ObservableObject, PropertyWrapper {
    enum InverseKeyPath {
        case toOne(WritableKeyPath<ValueEntity, InverseValue>)
        case oneToMany(WritableKeyPath<ValueEntity, InverseValue>)
        case manyToMany(WritableKeyPath<ValueEntity, RelatedModels<Parent>>)
    }
    
    var underlyingRecord: _opaque_DatabaseRecord?
    
    var name: String?
    var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration = .init(isOptional: false)
    var relationshipConfiguration: DatabaseSchema.Entity.RelationshipConfiguration = .init(destinationEntityName: "", inverseRelationshipName: nil, cardinality: .oneToOne, deleteRule: nil, isOrdered: false)
    
    let inverse: InverseKeyPath
    let deleteRule: NSDeleteRule?
    
    var wrappedValue_didSet_hash: AnyHashable?
    
    var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            do {
                return try Value.decode(from: underlyingRecord.unwrap(), forKey: .init(stringValue: name.unwrap()))
            } catch {
                return .init(noRelatedModels: ())
            }
        } set {
            defer {
                wrappedValue_didSet_hash = UUID()
            }
            
            if let underlyingRecord = underlyingRecord {
                try! underlyingRecord.encode(newValue, forKey: key.unwrap())
            }
        }
    }
    
    init(
        inverse: InverseKeyPath,
        deleteRule: NSDeleteRule? = nil
    ) {
        self.inverse = inverse
        self.deleteRule = deleteRule
    }
    
    func _runtime_initializePostNameResolution() {
        
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
    
    public func schema() -> DatabaseSchema.Entity.Property {
        DatabaseSchema.Entity.Relationship(
            name: name!,
            propertyConfiguration: propertyConfiguration,
            relationshipConfiguration: relationshipConfiguration
        )
    }
}
