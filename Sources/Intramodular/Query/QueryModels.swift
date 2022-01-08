//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow
import SwiftUIX
import Merge

/// A property wrapper type that makes fetch requests and retrieves the results from a Core Data store.
@propertyWrapper
public struct QueryModels<Model: Entity>: DynamicProperty {
    fileprivate class RequestOutputCoordinator: ObservableObject {
        private lazy var cancellables = Cancellables()
        private lazy var logger = os.Logger(subsystem: "com.vmanot.SwiftDB", category: "QueryModels.RequestOutputCoordinator<\(String(describing: Model.self))>")
        
        var queryRequest: QueryRequest<Model>!
        var _databaseRecordContext: _opaque_DatabaseRecordContext! {
            didSet {
                guard let context = _databaseRecordContext else {
                    return
                }
                
                context
                    ._opaque_objectWillChange
                    .sink(in: cancellables) { [unowned self] _ in
                        self.runQuery()
                    }
            }
        }
        
        @Published var output: QueryRequest<Model>.Output?
        
        init() {
            
        }
        
        func runQuery() {
            let queryTask = _databaseRecordContext.execute(queryRequest)
            
            queryTask.start()
            
            queryTask
                .successPublisher
                .receiveOnMainQueue()
                .sinkResult(in: cancellables) { result in
                    self.output = try? result.get()
                }
        }
    }
    
    @Environment(\.databaseRecordContext) var databaseRecordContext
    
    private let queryRequest: QueryRequest<Model>
    private let transaction: Transaction?
    private let animation: Animation?
    
    @StateObject private var coordinator = RequestOutputCoordinator()
    
    public var wrappedValue: QueryRequest<Model>.Output.Results {
        guard let output = coordinator.output else {
            return []
        }
        
        return output.results
    }
    
    public mutating func update() {
        if databaseRecordContext !== AnyDatabaseRecordContext.invalid, coordinator._databaseRecordContext == nil {
            coordinator.queryRequest = queryRequest
            coordinator._databaseRecordContext = databaseRecordContext
            
            coordinator.runQuery()
        }
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
        predicate: Predicate<Model>? = nil,
        animation: Animation? = nil
    ) {
        self.init(
            queryRequest: .init(
                predicate: predicate.map(AnyPredicate.init),
                sortDescriptors: sortDescriptors,
                fetchLimit: nil
            ),
            animation: animation
        )
    }
    
    public init() {
        self.init(sortDescriptors: [])
    }
}
