//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Runtime
import Swallow

/// An entity in a data schema.
public protocol Entity: _opaque_Entity, EntityRelatable, Model {
    associatedtype RelatableEntityType = Self
    
    typealias Relationship<Value: EntityRelatable, ValueEntity: Entity & Identifiable, InverseValue: EntityRelatable, InverseValueEntity: Entity & Identifiable> = EntityRelationship<Self, Value, ValueEntity, InverseValue, InverseValueEntity> where Self: Identifiable
    
    static var name: String { get }
}

// MARK: - Implementation -

extension Entity {
    public static var name: String {
        String(describing: Self.self)
    }
}

// MARK: - Auxiliary Implementation -

public struct _DefaultParentEntity: Entity {
    public static var name: String {
        Never.materialize(reason: .abstract)
    }
    
    public static var version: Version? {
        Never.materialize(reason: .abstract)
    }
    
    public init() {
        self = Never.materialize(reason: .abstract)
    }
}
