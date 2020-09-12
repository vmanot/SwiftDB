//
// Copyright (c) Vatsal Manot
//

import CoreData
import SwiftUIX

/// A property wrapper type that makes fetch requests and retrieves the results from a Core Data store.
@propertyWrapper
public struct FetchModels<Result: Entity>: DynamicProperty {
    @usableFromInline
    @FetchRequest var base: FetchedResults<NSManagedObject>
    @usableFromInline
    var wrappedValueHash: Int?
    
    public var wrappedValue: [Result] = []
    
    public mutating func update() {
        if wrappedValueHash != Set(base).hashValue {
            var hasher = Hasher()
            
            wrappedValueHash = hasher.finalize()
            wrappedValue = base.lazy.filter({
                $0.managedObjectContext != nil
            }).map({ object -> Result in
                hasher.combine(object)
                
                return Result(_runtime_underlyingObject: object)
            })
        }
    }
}

extension FetchModels {
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
        sortDescriptors: [NSSortDescriptor] = [],
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
    
    public init() {
        self.init(sortDescriptors: [])
    }
}
