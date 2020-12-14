//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow
import Swift

/// The schema of a data model.
///
/// This can loosely by considered the equivalent of an `NSManagedObjectModel`.
public protocol Schema: Named {
    typealias Entities = [_opaque_Entity.Type]
    
    /// The name of this schema.
    var name: String { get }
    
    /// The entities declared by this schema.
    @ArrayBuilder<_opaque_Entity.Type>
    var entities: Entities { get }
}

// MARK: - Implementation -

extension Schema {
    @inlinable
    public var name: String {
        String(describing: type(of: self))
    }
}
