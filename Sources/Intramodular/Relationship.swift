//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

public protocol EntityRelationship {
    
}

extension EntityRelatable {
    public static func from(base: NSManagedObject, key: AnyStringKey) throws -> Self {
        fatalError()
    }
}

public struct RelatedEntities<E: Entity>: EntityRelatable, Sequence {
    let base: Set<NSManagedObject>
    
    public func makeIterator() -> AnyIterator<E> {
        .init(base.lazy.map({ E.init(base: $0)! }).makeIterator())
    }
}

public struct Relationship<Value: EntityRelatable>: _opaque_PropertyAccessor {
    public var base: NSManagedObject?
    public var name: String?
    public let isOptional: Bool = false
    public let isTransient: Bool = false
    
    public func toEntityPropertyDescription() -> EntityPropertyDescription {
        fatalError()
    }
    
    public var wrappedValue: Value {
        try! Value.from(base: base.unwrap(), key: .init(stringValue: name.unwrap()))
    }
}
