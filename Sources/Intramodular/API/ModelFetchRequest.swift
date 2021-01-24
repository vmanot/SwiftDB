//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Swallow

/// A description of search criteria used to retrieve data from a persistent store.
public struct ModelFetchRequest<Result: Entity> {
    public var predicate: NSPredicate?
    public var sortDescriptors: [SortDescriptor]?
    public var fetchLimit: FetchLimit?
    
    public init(
        predicate: NSPredicate?,
        sortDescriptors: [SortDescriptor]?,
        fetchLimit: Int?
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit.map(PaginationCursor.offset).map(FetchLimit.cursor)
    }
}
