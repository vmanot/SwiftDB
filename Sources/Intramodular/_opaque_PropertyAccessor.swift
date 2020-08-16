//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
protocol _opaque_PropertyAccessor {
    var _opaque_modelEnvironment: _opaque_ModelEnvironment { get }
    
    var base: NSManagedObject? { get set }
    
    var name: String? { get set }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    func toEntityPropertyDescription() -> EntityPropertyDescription
}

/// A shadow protocol for `Attribute`.
protocol _opaque_Attribute: _opaque_PropertyAccessor {
    var type: EntityAttributeTypeDescription { get }
    var _opaque_initialValue: Any? { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
}
