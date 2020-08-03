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
    typealias Entities = [opaque_Entity.Type]
    
    @ArrayBuilder<opaque_Entity.Type>
    var entities: Entities { get }
}

