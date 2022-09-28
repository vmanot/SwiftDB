//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import SwiftUI

/// An space to manipulate and track changes to managed database records.
///
/// `DatabaseRecordContext` is inspired from `NSManagedObjectContext`.
public protocol DatabaseRecordContext: ObservableObject {
    associatedtype Database: SwiftDB.Database
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype RecordType where Record.RecordType == RecordType
    associatedtype RecordID: Hashable
    associatedtype RecordConfiguration = DatabaseRecordConfiguration<Self>

    typealias DatabaseContext = SwiftDB.DatabaseContext<Database>
    
    var databaseContext: DatabaseContext { get }

    typealias RecordCreateContext = DatabaseRecordCreateContext<Self>
    typealias ZoneQueryRequest = DatabaseZoneQueryRequest<Self>
    typealias SaveError = DatabaseRecordContextSaveError<Self>
        
    /// Create a database record associated with this context.
    func createRecord(
        withConfiguration _: DatabaseRecordConfiguration<Self>,
        context: RecordCreateContext
    ) throws -> Record
        
    /// Get the record ID associated with this record.
    func recordID(from record: Record) throws -> RecordID
    
    /// Get the zone associatdd with this record.
    func zone(for: Record) throws -> Zone?
    
    /// Mark a record for deletion in this record context.
    func delete(_: Record) throws
    
    /// Execute a zone query request within the zones captured by this record context.
    ///
    /// - Parameters:
    ///   - request: The query request to execute.
    func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error>
    
    /// Save the changes made in this record context.
    ///
    /// - Returns: A task representing the save operation.
    func save() -> AnyTask<Void, SaveError>
}

// MARK: - Implementation -

extension DatabaseRecordContext {
    public func execute(_ request: ZoneQueryRequest) async throws -> ZoneQueryRequest.Result {
        try await execute(request).value
    }
    
    public func save() async throws {
        try await save().value
    }
}
