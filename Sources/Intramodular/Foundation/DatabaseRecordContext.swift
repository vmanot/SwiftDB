//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

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
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    associatedtype RecordID: Hashable
    
    typealias FetchRequest = DatabaseFetchRequest<Self>
    typealias SaveError = DatabaseRecordContextSaveError<Self>
    
    func createRecord(ofType type: RecordType, name: String?, in zone: Zone?) throws -> Record
    
    func zone(for: Record) throws -> Zone?
    func update(_: Record) throws
    func delete(_: Record) throws
    
    func execute(_ request: FetchRequest) -> AnyTask<FetchRequest.Result, Error>
    
    func save() -> AnyTask<Void, SaveError>
}
