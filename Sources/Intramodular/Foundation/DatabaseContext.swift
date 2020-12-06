//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

public struct DatabaseObjectMergeConflict<Context: DatabaseContext> {
    let source: Context.Object
}

public struct DatabaseContextSaveError<Context: DatabaseContext>: Error {
    let mergeConflicts: [DatabaseObjectMergeConflict<Context>]?
    
    public init(
        mergeConflicts: [DatabaseObjectMergeConflict<Context>]?
    ) {
        self.mergeConflicts = mergeConflicts
    }
}

public protocol _opaque_DatabaseContext {
    
}

public protocol DatabaseContext: _opaque_DatabaseContext {
    associatedtype Object: DatabaseObject
    associatedtype ObjectType: LosslessStringConvertible
    associatedtype ObjectID: Hashable
    
    typealias SaveError = DatabaseContextSaveError<Self>
    
    func createObject(ofType: ObjectType) throws -> Object
    
    func update(_: Object) throws
    func delete(_: Object) throws
    
    func save() -> AnyTask<Void, SaveError>
}
