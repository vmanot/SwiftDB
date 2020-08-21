//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift
import SwiftUIX

// A property wrapper type that subscribes to an observable model and invalidates a view whenever the observable model changes.
@propertyWrapper
public struct ObservedModel<Model: Entity>: DynamicProperty {
    @usableFromInline
    @ObservedObject var _runtime_underlyingObject: NSManagedObject
    
    public var wrappedValue: Model
    
    @inlinable
    public init(wrappedValue: Model) {
        self._runtime_underlyingObject = wrappedValue._runtime_underlyingObject!
        self.wrappedValue = wrappedValue
    }
}
