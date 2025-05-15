//
// Copyright (c) Vatsal Manot
//

import Swallow

/// The schema of a data model.
public protocol Schema {
    // FIXME: This needs a `SchemaRepresentation` protocol to be created, right now it's a dumb type.
    typealias Body = [any Entity.Type]
    
    /// The body of this schema.
    /// Use this to compose and declare the entities & models encapsulated by this schema.
    @SchemaBuilder
    var body: Body { get }
}


