//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit.Database {
    public struct Transaction: DatabaseTransaction {
        public typealias Database = _CloudKit.Database
        
        let recordSpace: RecordSpace
        
        public func createRecord(
            withConfiguration configuration: RecordConfiguration
        ) throws -> Database.Record {
            try recordSpace.createRecord(withConfiguration: configuration)
        }

        public func executeSynchronously(_ request: Database.ZoneQueryRequest) throws -> Database.ZoneQueryRequest.Result {
            throw Never.Reason.impossible
        }

        /// Mark a record for deletion in this record space.
        public func delete(_ recordID: Database.Record.ID) throws {
            try recordSpace.delete(recordID)
        }
    }
    
    public struct TransactionExecutor: DatabaseTransactionExecutor {
        public typealias Database = _CloudKit.Database
        
        let recordSpace: RecordSpace
        
        init(recordSpace: RecordSpace) {
            self.recordSpace = recordSpace
        }
        
        public func execute<R>(
            _ body: @escaping (Transaction) throws -> R
        ) async throws -> R {
            TODO.unimplemented
        }
        
        public func execute<R>(
            queryRequest: Database.ZoneQueryRequest,
            _ body: @escaping (Database.ZoneQueryRequest.Result) throws -> R
        ) async throws -> R {
            TODO.unimplemented
        }
        
        public func executeSynchronously<R>(
            _ body: @escaping (Transaction) throws -> R
        ) throws -> R {
            TODO.unimplemented
        }
    }
}
