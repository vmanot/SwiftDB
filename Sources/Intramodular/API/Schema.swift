//
// Copyright (c) Vatsal Manot
//

import Swallow

/// The schema of a data model.
public protocol Schema {
    typealias Body = [_opaque_Entity.Type]
    
    /// The body of this schema.
    /// Use this to compose and declare the entities & models encapsulated by this schema.
    @SchemaBuilder
    var body: Body { get }
}
