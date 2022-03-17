//
// Copyright (c) Vatsal Manot
//

import Swallow

@propertyWrapper
public struct _RelationshipToMany<Source: Entity & Identifiable, Destination: Entity & Identifiable> {
    public var wrappedValue: RelatedModels<Destination> {
        fatalError()
    }
    
    public init(inverse: KeyPath<Destination, Source>) {
        
    }
}

@propertyWrapper
public struct _RelationshipToOne<Source: Entity & Identifiable, Destination: Entity> {
    public var wrappedValue: Destination? {
        fatalError()
    }
    
    public init(inverse: KeyPath<Destination, Source?>) {
        
    }
}

extension Entity where Self: Identifiable {
    public typealias RelationshipToOne<Destination: Entity & Identifiable> = _RelationshipToOne<Self, Destination>
    public typealias RelationshipToMany<Destination: Entity & Identifiable> = _RelationshipToMany<Self, Destination>
}
