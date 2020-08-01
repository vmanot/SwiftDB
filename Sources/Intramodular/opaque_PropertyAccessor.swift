//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
public protocol opaque_PropertyAccessor {
    var name: String? { get set }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    func toEntityPropertyDescription() -> EntityPropertyDescription
}

/// A shadow protocol for `Attribute`.
public protocol opaque_Attribute: opaque_PropertyAccessor {
    var type: EntityAttributeTypeDescription { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
}
