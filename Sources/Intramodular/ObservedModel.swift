//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift
import SwiftUIX

// A property wrapper type that subscribes to an observable model and invalidates a view whenever the observable model changes.
@propertyWrapper
public struct ObservedModel<Model: Entity>: DynamicProperty {
    @ObservedObject
    private var base: NSManagedObject
    
    public var wrappedValue: Model
    
    public init(wrappedValue: Model) {
        self.base = wrappedValue.base!
        self.wrappedValue = wrappedValue
    }
}
