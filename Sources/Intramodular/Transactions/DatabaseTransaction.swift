//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol DatabaseTransaction {
    associatedtype Database: SwiftDB.Database

    typealias Record = Database.Record
    typealias RecordConfiguration = DatabaseRecordConfiguration<Database>
    typealias RecordUpdate = DatabaseRecordUpdate<Database>

    func createRecord(withConfiguration _: RecordConfiguration) throws -> Database.Record
    func updateRecord(_ recordID: Record.ID, with update: RecordUpdate) throws
    func executeSynchronously(_ request: Database.ZoneQueryRequest) throws -> Database.ZoneQueryRequest.Result
    func delete(_: Database.Record.ID) throws
}
