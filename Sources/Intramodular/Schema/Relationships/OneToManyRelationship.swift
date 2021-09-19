//
//  File.swift
//  
//
//  Created by Vatsal Manot on 15/09/21.
//

import Foundation

@propertyWrapper
public struct _OneToManyRelationship<Source: Entity, Destination: Entity & Identifiable> {
    public var wrappedValue: RelatedModels<Destination> {
        fatalError()
    }
    
    public init(inverse: KeyPath<Destination, Optional<Source>>) {
        
    }
}

@propertyWrapper
public struct _RelationshipToOne<Source: Entity & Identifiable, Destination: Entity> {
    public var wrappedValue: Destination? {
        fatalError()
    }
    
    public init(inverse: KeyPath<Destination, RelatedModels<Source>>) {
        
    }
}

extension Entity where Self: Identifiable {
    public typealias RelationshipToOne<Destination: Entity & Identifiable> = _RelationshipToOne<Self, Destination>
    public typealias RelationshipToMany<Destination: Entity & Identifiable> = _OneToManyRelationship<Self, Destination>
}

