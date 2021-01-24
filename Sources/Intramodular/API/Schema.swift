//
// Copyright (c) Vatsal Manot
//

import Swallow

/// The schema of a data model.
///
/// This can loosely by considered the equivalent of an `NSManagedObjectModel` for CoreData.
public protocol Schema {
    typealias Body = [_opaque_Entity.Type]
    
    /// The body of this schema.
    /// Use this to compose and declare the entities & models encapsulated by this schema.
    @SchemaBuilder
    var body: Body { get }
}
