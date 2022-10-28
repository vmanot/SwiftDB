//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import SwiftUI

/// An space to manipulate and track changes to managed database records.
///
/// `DatabaseRecordSpace` is inspired from `NSManagedObjectContext`.
public protocol DatabaseRecordSpace: ObservableObject, Sendable {
    associatedtype Database: SwiftDB.Database
    associatedtype Zone: DatabaseZone
    associatedtype Record: DatabaseRecord
    associatedtype QuerySubscription: DatabaseQuerySubscription
    
    typealias RecordConfiguration = DatabaseRecordConfiguration<Self>
    typealias RecordCreateContext = DatabaseRecordCreateContext<Self>
    typealias ZoneQueryRequest = DatabaseZoneQueryRequest<Self>
    typealias SaveError = DatabaseRecordSpaceSaveError<Self>
    
    /// Create a database record associated with this context.
    func createRecord(
        withConfiguration _: DatabaseRecordConfiguration<Self>,
        context: RecordCreateContext
    ) throws -> Record
    
    /// Mark a record for deletion in this record space.
    func delete(_: Record) throws
    
    /// Execute a zone query request within the zones captured by this record space.
    ///
    /// - Parameters:
    ///   - request: The query request to execute.
    func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error>
    
    /// A query subscription for a given zone.
    func querySubscription(for request: ZoneQueryRequest) throws -> QuerySubscription
    
    /// Save the changes made in this record space.
    ///
    /// - Returns: A task representing the save operation.
    func save() -> AnyTask<Void, SaveError>
}

// MARK: - Extensions -

extension DatabaseRecordSpace {
    public func execute(_ request: ZoneQueryRequest) async throws -> ZoneQueryRequest.Result {
        try await execute(request).value
    }
    
    public func save() async throws {
        try await save().value
    }
}
