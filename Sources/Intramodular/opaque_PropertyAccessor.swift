//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
protocol opaque_PropertyAccessor {
    var base: NSManagedObject? { get set }
    
    var name: String? { get set }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    func toEntityPropertyDescription() -> EntityPropertyDescription
}

/// A shadow protocol for `Attribute`.
protocol opaque_Attribute: opaque_PropertyAccessor {
    var type: EntityAttributeTypeDescription { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
}
