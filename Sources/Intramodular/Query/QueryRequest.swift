//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Swallow

/// A description of search criteria used to retrieve data from a persistent store.
public struct QueryRequest<Result: Entity> {
    public var predicate: NSPredicate?
    public var sortDescriptors: [AnySortDescriptor]?
    public var fetchLimit: FetchLimit?
    
    @_disfavoredOverload
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

extension QueryRequest {
    public init(
        predicate: NSPredicate?,
        sortDescriptors: [AnySortDescriptor]?,
        fetchLimit: Int?
    ) {
        self.init(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fetchLimit: fetchLimit.map({ .cursor(.offset($0)) })
        )
    }
}
