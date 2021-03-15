//
// Copyright (c) Vatsal Manot
//

import Swift

public enum EntityCardinality {
    case one
    case many
}

public enum EntityRelationshipCardinality: String, Codable {
    case oneToOne = "one-to-one"
    case oneToMany = "one-to-many"
    case manyToOne = "many-to-one"
    case manyToMany = "many-to-many"
    
    public init(source: EntityCardinality, destination: EntityCardinality) {
        switch (source, destination) {
            case (.one, .one):
                self = .oneToOne
            case (.one, .many):
                self = .oneToMany
            case (.many, .one):
                self = .oneToMany
            case (.many, .many):
                self = .manyToMany
        }
    }
}
