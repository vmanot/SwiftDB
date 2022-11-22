//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol DatabaseTransaction {
    associatedtype Database: SwiftDB.Database
    
    typealias RecordConfiguration = DatabaseRecordConfiguration<Database>
    
    func createRecord(withConfiguration _: RecordConfiguration) throws -> Database.Record
    func executeSynchronously(_ request: Database.ZoneQueryRequest) throws -> Database.ZoneQueryRequest.Result
    func delete(_: Database.Record) throws
}
