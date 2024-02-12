//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// A write transaction executor.
///
/// Inspiration:
/// - https://github.com/groue/GRDB.swift#transactions-and-savepoints
/// - https://mongodb.com/docs/realm/sdk/swift/crud/create/
public protocol DatabaseTransactionExecutor {
    associatedtype Transaction: DatabaseTransaction

    typealias Database = Transaction.Database

    /// Asynchronously executes a database transaction.
    func execute<R>(
        _ body: @escaping (Transaction) throws -> R
    ) async throws -> R

    func execute<R>(
        queryRequest: Database.ZoneQueryRequest,
        _ body: @escaping (Database.ZoneQueryRequest.Result) throws -> R
    ) async throws -> R

    /// Synchronously executes a database transaction.
    func executeSynchronously<R>(
        _ body: @escaping (Transaction) throws -> R
    ) throws -> R
}
