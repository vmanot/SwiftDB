//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

public protocol DatabaseLocation {
    
}

public struct DatabaseObjectMergeConflict<Context: DatabaseObjectContext> {
    let source: Context.Object
}

public struct DatabaseObjectContextSaveError<Context: DatabaseObjectContext>: Error {
    let mergeConflicts: [DatabaseObjectMergeConflict<Context>]?
    
    public init(
        mergeConflicts: [DatabaseObjectMergeConflict<Context>]?
    ) {
        self.mergeConflicts = mergeConflicts
    }
}

public protocol DatabaseObjectContext {
    associatedtype Zone: DatabaseZone
    associatedtype Object: DatabaseObject
    associatedtype ObjectType: Codable & LosslessStringConvertible
    associatedtype ObjectID: Hashable
    
    typealias SaveError = DatabaseObjectContextSaveError<Self>
    
    func createObject(ofType type: ObjectType, name: String?, in zone: Zone?) throws -> Object
    func zone(for object: Object) throws -> Zone?
    func update(_ object: Object) throws
    func delete(_ object: Object) throws
    
    func save() -> AnyTask<Void, SaveError>
}
