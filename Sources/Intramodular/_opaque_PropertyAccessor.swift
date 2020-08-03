//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
protocol _opaque_PropertyAccessor {
    var base: NSManagedObject? { get set }
    
    var name: String? { get set }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    func toEntityPropertyDescription() -> EntityPropertyDescription
}

/// A shadow protocol for `Attribute`.
protocol _opaque_Attribute: _opaque_PropertyAccessor {
    var type: EntityAttributeTypeDescription { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
}
