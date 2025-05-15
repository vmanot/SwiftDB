//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow
import SwiftUIX
import Merge

/// A property wrapper type that makes fetch requests and retrieves the results from a database.
@propertyWrapper
public struct QueryModels<Model: Entity>: DynamicProperty {
    public typealias WrappedValue = QueryRequest<Model>.Output.Results
    
    @Environment(\.database) var database
    
    private let queryRequest: QueryRequest<Model>
    private let transaction: Transaction?
    private let animation: Animation?
    
    @StateObject private var coordinator = RequestOutputCoordinator()
    
    public var wrappedValue: WrappedValue {
        coordinator.querySubscription?.results ?? []
    }
    
    public var projectedValue: Self {
        self
    }
    
    public mutating func update() {
        coordinator.queryRequest = queryRequest
        coordinator.database = database
    }
    
    public init(
        queryRequest: QueryRequest<Model>,
        animation: Animation? = nil
    ) {
        self.queryRequest = queryRequest
        self.transaction = nil
        self.animation = animation
    }
    
    public init(
        queryRequest: QueryRequest<Model>,
        transaction: Transaction
    ) {
        self.queryRequest = queryRequest
        self.transaction = transaction
        self.animation = nil
    }
    
    public init(
        sortDescriptors: [AnySortDescriptor] = [],
        predicate: CocoaPredicate<Model>? = nil,
        animation: Animation? = nil
    ) {
        self.init(
            queryRequest: .init(
                predicate: predicate.map(AnyPredicate.init),
                sortDescriptors: sortDescriptors,
                fetchLimit: nil,
                scope: nil
            ),
            animation: animation
        )
    }
    
    public init() {
        self.init(sortDescriptors: [])
    }
}

extension QueryModels {
    public func remove(atOffsets offsets: IndexSet) async throws {
        for item in offsets.map({ wrappedValue[$0] }) {
            try await database.delete(item)
        }
    }
    
    @_disfavoredOverload
    @MainActor
    public func remove(atOffsets offsets: IndexSet) {
        Task { @MainActor in
            for item in offsets.map({ wrappedValue[$0] }) {
                try await database.delete(item)
            }
        }
    }
}

// MARK: - Auxiliary

extension QueryModels {
    fileprivate class RequestOutputCoordinator: Logging, ObservableObject, @unchecked Sendable {
        var queryRequest: QueryRequest<Model>?
        
        @MainActor(unsafe)
        @MyPublishedObject var querySubscription: QuerySubscription<Model>?
        
        var database: AnyDatabaseContainer.LiveAccess? {
            didSet {
                guard querySubscription == nil || oldValue !== database else {
                    return
                }
                
//                querySubscription = nil
                
                guard let queryRequest, let database, database.isInitialized else {
                    return
                }

                DispatchQueue.main.async {
                    do {
                        self.querySubscription = try database.querySubscription(for: queryRequest)
                    } catch {
                        self.logger.error(error)
                    }
                }
            }
        }
        
        init() {

        }
    }
}

@propertyWrapper
public struct MyPublishedObject<Value> {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) where Value: ObservableObject {
        self.wrappedValue = wrappedValue
    }
    
    public init(wrappedValue: Value) where Value: OptionalObservableObject {
        self.wrappedValue = wrappedValue
    }
    
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value where OuterSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            if observed[keyPath: storageKeyPath].cancellable == nil {
                observed[keyPath: storageKeyPath].setup(observed)
            }
            return observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            observed.objectWillChange.send() // willSet
            observed[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    private var cancellable: AnyCancellable?
    
    private mutating func setup<OuterSelf: ObservableObject>(_ enclosingInstance: OuterSelf) where OuterSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        if let optionalObject = wrappedValue as? OptionalObservableObject {
            cancellable = optionalObject.objectWillChange?.sink(receiveValue: { [weak enclosingInstance] _ in
                (enclosingInstance?.objectWillChange)?.send()
            })
        } else if let object = wrappedValue as? any ObservableObject {
            cancellable = (object.objectWillChange as? ObservableObjectPublisher)?.sink(receiveValue: { [weak enclosingInstance] _ in
                (enclosingInstance?.objectWillChange)?.send()
            })
        }
    }
}

// 用于处理可选的 ObservableObject 的协议
public protocol OptionalObservableObject {
    var objectWillChange: ObservableObjectPublisher? { get }
}

// 扩展 Optional 以符合 OptionalObservableObject 协议
extension Optional: OptionalObservableObject where Wrapped: ObservableObject, Wrapped.ObjectWillChangePublisher == ObservableObjectPublisher {
    public var objectWillChange: ObservableObjectPublisher? {
        switch self {
        case .some(let object):
            return object.objectWillChange
        case .none:
            return nil
        }
    }
}
