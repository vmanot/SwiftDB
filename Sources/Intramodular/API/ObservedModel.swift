//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Swift
import SwiftUIX

// A property wrapper type that subscribes to an observable model and invalidates a view whenever the observable model changes.
@propertyWrapper
public struct ObservedModel<Model: Entity>: DynamicProperty {
    @usableFromInline
    @ObservedObject var _underlyingDatabaseRecord: NSManagedObject
    
    @State public var wrappedValue: Model
    
    public var projectedValue: Binding<Model> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public init(wrappedValue: Model) {
        self._underlyingDatabaseRecord = (wrappedValue._underlyingDatabaseRecord as! _CoreData.DatabaseRecord).base
        self._wrappedValue = .init(wrappedValue: wrappedValue)
    }
}

public class _PublisherToObservableObject: ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var cancellable: Cancellable?
    
    func setPublisher<P: Publisher>(_ publisher: P) where P.Failure == Never {
        cancellable = publisher.publish(to: objectWillChange).sink()
    }
}
