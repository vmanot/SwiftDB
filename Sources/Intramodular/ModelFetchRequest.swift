//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

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

extension ModelFetchRequest {
    public func toNSFetchRequest() -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: Result.name)
        
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        
        return request
    }
}
