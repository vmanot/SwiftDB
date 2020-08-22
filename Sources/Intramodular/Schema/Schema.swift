//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// The schema of a data model.
///
/// This can loosely by considered the equivalent of an `NSManagedObjectModel`.
public protocol Schema {
    typealias Entities = [_opaque_Entity.Type]
    
    var name: String { get }
    
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
