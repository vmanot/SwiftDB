//
// Copyright (c) Vatsal Manot
//

import Swift

public enum EntityCardinality {
    case one
    case many
}

public enum EntityRelationshipCardinality {
    case oneToOne
    case oneToMany
    case manyToOne
    case manyToMany
    
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
