//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
@usableFromInline
protocol _opaque_PropertyAccessor {
    var _opaque_modelEnvironment: _opaque_ModelEnvironment { get set }
    
    var underlyingObject: NSManagedObject? { get set }
    
    var name: String? { get set }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    mutating func _runtime_initialize()
    
    func toEntityPropertyDescription() -> EntityPropertyDescription
}

/// A shadow protocol for `Attribute`.
protocol _opaque_Attribute: _opaque_PropertyAccessor {
    var type: EntityAttributeTypeDescription { get }
    var _opaque_initialValue: Any? { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    mutating func _runtime_encodeDefaultValueIfNecessary()
}

// MARK: - Implementation -

extension _opaque_PropertyAccessor {
    @usableFromInline
    mutating func _runtime_initialize() {
        
    }
}

extension _opaque_PropertyAccessor where Self: _opaque_Attribute {
    @usableFromInline
    mutating func _runtime_initialize() {
        _runtime_encodeDefaultValueIfNecessary()
    }
}
