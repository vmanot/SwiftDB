//
// Copyright (c) Vatsal Manot
//

import Swallow

/// The schema of a data model.
///
/// This can loosely by considered the equivalent of an `NSManagedObjectModel` for CoreData.
public protocol Schema: Named {
    typealias Body = [_opaque_Entity.Type]
    
    /// The name of this schema.
    var name: String { get }
    
    /// The entities declared by this schema.
    @SchemaBuilder
    var body: Body { get }
}

// MARK: - Implementation -

extension Schema {
    @inlinable
    public var name: String {
        String(describing: type(of: self))
    }
}
