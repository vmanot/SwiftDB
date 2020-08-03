//
// Copyright (c) Vatsal Manot
//

import SwiftUI

/// A property wrapper type that makes fetch requests and retrieves the results from a Core Data store.
public struct FetchedModels<Result: Entity>: DynamicProperty {
    @FetchRequest var base: FetchedResults<NSManagedObject>
    
    public var wrappedValue: AnyRandomAccessCollection<Result> {
        .init(base.lazy.map({ Result(base: $0)! }))
    }
}

extension FetchedModels {
    public init(
        fetchRequest: ModelFetchRequest<Result>,
        animation: Animation? = nil
    ) {
        _base = .init(fetchRequest: fetchRequest.toNSFetchRequest(), animation: animation)
    }
    
    public init(
        fetchRequest: ModelFetchRequest<Result>,
        transaction: Transaction
    ) {
        _base = .init(fetchRequest: fetchRequest.toNSFetchRequest(), transaction: transaction)
    }
    
    public init(
        sortDescriptors: [NSSortDescriptor],
        predicate: NSPredicate? = nil,
        animation: Animation? = nil
    ) {
        self.init(
            fetchRequest: .init(
                predicate: predicate,
                sortDescriptors: sortDescriptors,
                fetchLimit: nil
            ),
            animation: animation
        )
    }
}

