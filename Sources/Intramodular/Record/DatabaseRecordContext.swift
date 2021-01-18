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

public struct DatabaseRecordConfiguration<Context: DatabaseRecordContext> {
    public let recordType: Context.RecordType
    public let recordID: Context.RecordID?
    public let zone: Context.Zone?
    public let entity: DatabaseSchema.Entity?
}

public protocol DatabaseRecordContext {
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    associatedtype RecordID: Hashable
    associatedtype RecordConfiguration = DatabaseRecordConfiguration<Self>
    
    typealias FetchRequest = DatabaseFetchRequest<Self>
    typealias SaveError = DatabaseRecordContextSaveError<Self>
    
    func createRecord(withConfiguration _: DatabaseRecordConfiguration<Self>) throws -> Record
    
    func recordID(from record: Record) throws -> RecordID
    
    func zone(for: Record) throws -> Zone?
    func update(_: Record) throws
    func delete(_: Record) throws
    
    func execute(_ request: FetchRequest) -> AnyTask<FetchRequest.Result, Error>
    
    func save() -> AnyTask<Void, SaveError>
}
