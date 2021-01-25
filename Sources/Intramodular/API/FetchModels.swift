//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Swallow
import SwiftUIX

/// A property wrapper type that makes fetch requests and retrieves the results from a Core Data store.
@propertyWrapper
public struct FetchModels<Result: Entity>: DynamicProperty {
    @usableFromInline
    @FetchRequest var base: FetchedResults<NSManagedObject>
    
    public var wrappedValue: [Result] = []
    @usableFromInline
    var wrappedValueHash: Int?
    
    public mutating func update() {
        guard needsUpdate else {
            return
        }
        
        var hasher = Hasher()
        
        wrappedValue = base.lazy.filter({
            !$0.isDeleted && $0.managedObjectContext != nil
        }).map({ object -> Result in
            hasher.combine(object)
            
            return Result(_underlyingDatabaseRecord: _CoreData.DatabaseRecord(base: object), context: DatabaseRecordCreateContext<_CoreData.DatabaseRecordContext>())
        })
        
        wrappedValueHash = hasher.finalize()
    }
    
    private var needsUpdate: Bool {
        guard base.count == wrappedValue.count else {
            return true
        }
        
        return wrappedValueHash != getBaseHash()
    }
    
    private func getBaseHash() -> Int {
        var hasher = Hasher()
        
        base.forEach({ hasher.combine($0) })
        
        return hasher.finalize()
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
        sortDescriptors: [SortDescriptor] = [],
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

// MARK: - Auxiliary Implementation -

fileprivate extension ModelFetchRequest {
    func toNSFetchRequest() -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: Result.name)
        
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors?.map({ $0 as NSSortDescriptor })
        
        if let fetchLimit = fetchLimit {
            if case let .cursor(.offset(offset)) = fetchLimit {
                request.fetchLimit = offset
            } else {
                fatalError(reason: .unimplemented)
            }
        }
        
        return request
    }
}
