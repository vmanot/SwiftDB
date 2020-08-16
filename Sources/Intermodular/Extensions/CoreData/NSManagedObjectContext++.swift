//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

extension NSManagedObjectContext {
    /// Publisher that emits lists of entities of the defined entity type of the source managed object context whenever updates to the objects occur.
    ///
    /// - Parameter entity: The entity type to receive updates for
    /// - Returns: Publisher that emits up-to-date lists of the entities.
    public func publisher<Entity: NSManagedObject>(for entity: Entity.Type) -> FetchedResultsPublisher<Entity> {
        .init(managedObjectContext: self)
    }
}
