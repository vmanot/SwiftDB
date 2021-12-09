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
    
    public var predicate: NSPredicate?
    public var sortDescriptors: [AnySortDescriptor]?
    public var fetchLimit: FetchLimit?
    
    public init(
        predicate: NSPredicate?,
        sortDescriptors: [AnySortDescriptor]?,
        fetchLimit: FetchLimit?
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }
}
