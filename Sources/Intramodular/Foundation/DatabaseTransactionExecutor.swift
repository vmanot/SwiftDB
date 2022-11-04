//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// A write transaction executor.
///
/// References:
/// - https://github.com/groue/GRDB.swift#transactions-and-savepoints
/// - https://mongodb.com/docs/realm/sdk/swift/crud/create/
public protocol DatabaseTransactionExecutor {
    associatedtype Transaction: DatabaseTransaction
    
    func execute<R>(_ body: (Transaction) -> R) throws
}

public protocol DatabaseTransaction {
    associatedtype Database: SwiftDB.Database
    
    typealias RecordConfiguration = DatabaseRecordConfiguration<Database>
    
    func createRecord(withConfiguration _: RecordConfiguration) throws -> Database.Record
    
    /// Mark a record for deletion in this record space.
    func delete(_: Database.Record) throws
}
