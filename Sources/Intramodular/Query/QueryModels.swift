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
        guard let output = coordinator.output else {
            return []
        }
        
        return output.results
    }
    
    public var projectedValue: Self {
        self
    }
    
    public mutating func update() {
        if database.isInitialized && coordinator.database == nil {
            coordinator.queryRequest = queryRequest
            coordinator.database = database
            
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

extension QueryModels {
    public func remove(atOffsets offsets: IndexSet) {
        for item in offsets.map({ wrappedValue[$0] }) {
            try! database.delete(item)
        }
    }
}

// MARK: - Auxiliary Implementation -

extension QueryModels {
    fileprivate class RequestOutputCoordinator: Loggable, ObservableObject, @unchecked Sendable {
        private var databaseListener: AnyCancellable?
        
        var queryRequest: QueryRequest<Model>!
        var database: LiveDatabaseAccess? {
            didSet {
                databaseListener = database.map { database in
                    (database.base as! _AnyDatabaseRecordContextTransaction)
                        .willChangePublisher()
                        .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main) // FIXME: Hack!!!
                        .sink { [unowned self] _ in
                            self.runQuery()
                        }
                }
            }
        }
        
        @Published var output: QueryRequest<Model>.Output?
        
        init() {
            logger.dumpToConsole = true
        }
        
        func runQuery() {
            Task { @MainActor in
                do {
                    let queryTask = try database.unwrap().queryExecutionTask(for: queryRequest)
                    
                    try Task.checkCancellation()
                    
                    queryTask.start()
                    
                    self.output = try await queryTask.value
                } catch {
                    logger.error(error)
                    
                    assertionFailure()
                }
            }
        }
    }
}
