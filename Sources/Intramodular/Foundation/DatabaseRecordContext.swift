//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

public struct DatabaseRecordMergeConflict<Context: DatabaseRecordContext> {
    let source: Context.Record
}

public struct DatabaseRecordContextSaveError<Context: DatabaseRecordContext>: Error {
    let mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    
    public init(
        mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    ) {
        self.mergeConflicts = mergeConflicts
    }
}

public protocol DatabaseRecordContext {
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype RecordType: Codable & LosslessStringConvertible
    associatedtype RecordID: Hashable
    
    typealias SaveError = DatabaseRecordContextSaveError<Self>
    
    func createRecord(ofType type: RecordType, name: String?, in zone: Zone?) throws -> Record
    
    func zone(for: Record) throws -> Zone?
    func update(_: Record) throws
    func delete(_: Record) throws
    
    func save() -> AnyTask<Void, SaveError>
}
