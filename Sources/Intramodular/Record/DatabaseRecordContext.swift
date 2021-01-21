//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

public protocol DatabaseRecordContext {
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype RecordType: Codable & Hashable & LosslessStringConvertible
    associatedtype RecordID: Hashable
    associatedtype RecordConfiguration = DatabaseRecordConfiguration<Self>
    
    typealias RecordCreateContext = DatabaseRecordCreateContext<Self>
    typealias FetchRequest = DatabaseFetchRequest<Self>
    typealias SaveError = DatabaseRecordContextSaveError<Self>
    
    func createRecord(
        withConfiguration _: DatabaseRecordConfiguration<Self>,
        context: RecordCreateContext
    ) throws -> Record
    
    func recordID(from record: Record) throws -> RecordID
    
    func zone(for: Record) throws -> Zone?
    func update(_: Record) throws
    func delete(_: Record) throws
    
    func execute(_ request: FetchRequest) -> AnyTask<FetchRequest.Result, Error>
    
    func save() -> AnyTask<Void, SaveError>
}
