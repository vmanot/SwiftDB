//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Swallow

/// A description of search criteria used to retrieve data from a persistent store.
public struct QueryRequest<Model> {
    public struct Output {
        public typealias Results = [Model]
        
        public let results: [Model]
    }
    
    public var predicate: AnyPredicate?
    public var sortDescriptors: [AnySortDescriptor]?
    public var fetchLimit: FetchLimit?
    
    @_disfavoredOverload
    public init(
        predicate: AnyPredicate?,
        sortDescriptors: [AnySortDescriptor]?,
        fetchLimit: FetchLimit?
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }
    
    public init(
        predicate: Predicate<Model>?,
        sortDescriptors: [AnySortDescriptor]?,
        fetchLimit: FetchLimit?
    ) {
        self.init(
            predicate: predicate.map(AnyPredicate.init),
            sortDescriptors: sortDescriptors,
            fetchLimit: nil
        )
    }
}
