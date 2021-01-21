//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

/// A description of search criteria used to retrieve data from a persistent store.
public struct ModelFetchRequest<Result: Entity> {
    public var predicate: NSPredicate?
    public var sortDescriptors: [NSSortDescriptor]?
    public var fetchLimit: Int?
    
    public init(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]?,
        fetchLimit: Int?
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }
}
