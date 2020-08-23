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
    
    @State public var wrappedValue: Model
    
    public var projectedValue: Binding<Model> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public init(wrappedValue: Model) {
        self._runtime_underlyingObject = wrappedValue._runtime_underlyingObject!
        self._wrappedValue = .init(wrappedValue: wrappedValue)
    }
}
