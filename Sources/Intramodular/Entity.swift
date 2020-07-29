//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

public protocol opaque_Entity: Initiable {
    static var name: String { get }
    static var managedObjectClassName: String { get }
}

public protocol Entity: opaque_Entity, DataModel {
    static var name: String { get }
}

// MARK: - Implementation -

extension opaque_Entity where Self: Entity {
    public static var managedObjectClassName: String {
        NSStringFromClass(_EntityToNSManagedObjectAdaptor<Self>.self)
    }
}

@usableFromInline
class _EntityToNSManagedObjectAdaptor<T: Entity>: NSXManagedObject {
    
}
