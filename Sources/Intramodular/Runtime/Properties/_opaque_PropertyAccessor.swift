//
// Copyright (c) Vatsal Manot
//

import CoreData
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
@usableFromInline
protocol _opaque_PropertyAccessor: _opaque_PropertyWrapper {
    var _opaque_modelEnvironment: _opaque_ModelEnvironment { get set }
    
    mutating func _runtime_initialize()
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    mutating func _runtime_encodeDefaultValueIfNecessary()
    
    var underlyingObject: DatabaseRecord? { get set }
    
    var name: String? { get set }
    var key: AnyStringKey? { get }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    func decode(from _: Decoder) throws
    func encode(to _: Encoder) throws
    
    func toEntityPropertyDescription() -> EntityPropertyDescription
}

// MARK: - Implementation -

extension _opaque_PropertyAccessor where Self: PropertyWrapper {
    @usableFromInline
    var key: AnyStringKey? {
        name.map(AnyStringKey.init(stringValue:))
    }
    
    @usableFromInline
    mutating func _runtime_initialize() {
        _runtime_encodeDefaultValueIfNecessary()
    }
    
    @usableFromInline
    mutating func _runtime_encodeDefaultValueIfNecessary() {
        guard let underlyingObject = underlyingObject, let name = name else {
            return
        }
        
        if !isOptional && !underlyingObject.containsValue(forKey: AnyStringKey(stringValue: name)) {
            _ = self.wrappedValue // force an evaluation
        }
    }
}
