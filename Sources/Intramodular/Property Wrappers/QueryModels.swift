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
        predicate: Predicate<Model>? = nil,
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
}

// MARK: - Auxiliary -

extension QueryModels {
    fileprivate class RequestOutputCoordinator: Loggable, ObservableObject, @unchecked Sendable {
        var queryRequest: QueryRequest<Model>?
        
        @PublishedObject var querySubscription: QuerySubscription<Model>?
        
        @PublishedObject var database: AnyDatabaseContainer.LiveAccess? {
            didSet {
                guard querySubscription == nil || oldValue !== database else {
                    return
                }
                
                querySubscription = nil
                
                guard let queryRequest, let database, database.isInitialized else {
                    return
                }
                
                do {
                    querySubscription = try database.querySubscription(for: queryRequest)
                } catch {
                    logger.error(error)
                }
            }
        }
        
        init() {
            logger.dumpToConsole = true
        }
    }
}
