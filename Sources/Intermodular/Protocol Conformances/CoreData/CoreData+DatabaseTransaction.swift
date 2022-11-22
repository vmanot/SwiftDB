//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public struct Transaction: DatabaseTransaction {
        public typealias Database = _CoreData.Database

        let recordSpace: RecordSpace

        public func createRecord(
            withConfiguration configuration: RecordConfiguration
        ) throws -> Database.Record {
            try recordSpace.createRecord(withConfiguration: configuration)
        }

        public func executeSynchronously(_ request: Database.ZoneQueryRequest) throws -> Database.ZoneQueryRequest.Result {
            let nsFetchRequests = try request.toNSFetchRequests(recordSpace: recordSpace)

            if request.sortDescriptors.isNil {
                let records = try nsFetchRequests
                    .flatMap { fetchRequest in
                        try recordSpace.nsManagedObjectContext
                            .fetch(fetchRequest)
                            .map({ Record(rawObject: $0) })
                    }

                return Database.ZoneQueryRequest.Result(records: records)
            } else {
                var fetchedNSManagedObjects: [NSManagedObject] = []

                for nsFetchRequest in nsFetchRequests {
                    let fetchedResultsController = NSFetchedResultsController<NSManagedObject>(
                        fetchRequest: nsFetchRequest,
                        managedObjectContext: recordSpace.nsManagedObjectContext,
                        sectionNameKeyPath: nil,
                        cacheName: nil
                    )

                    try fetchedResultsController.performFetch()

                    fetchedNSManagedObjects.append(contentsOf: fetchedResultsController.fetchedObjects ?? [])
                }

                return Database.ZoneQueryRequest.Result(records: fetchedNSManagedObjects.map({ Record(rawObject: $0) }))
            }
        }

        public func delete(_ record: Database.Record) throws {
            try recordSpace.delete(record)
        }
    }

    public struct TransactionExecutor: DatabaseTransactionExecutor {
        public typealias Database = _CoreData.Database
        
        let recordSpace: RecordSpace

        init(recordSpace: RecordSpace) {
            self.recordSpace = recordSpace
        }

        public func execute<R>(_ body: @escaping (Transaction) throws -> R) async throws -> R {
            let nsManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

            nsManagedObjectContext.parent = recordSpace.nsManagedObjectContext

            let childRecordSpace = RecordSpace(
                databaseContext: recordSpace.databaseContext,
                managedObjectContext: nsManagedObjectContext,
                affectedStores: recordSpace.affectedStores
            )

            do {
                let result = try await nsManagedObjectContext.perform {
                    let result = try body(Transaction(recordSpace: childRecordSpace))

                    try nsManagedObjectContext.save()

                    return result
                }

                return result
            }
        }
        
        public func execute<R>(
            queryRequest: Database.ZoneQueryRequest,
            _ body: @escaping (Database.ZoneQueryRequest.Result) throws -> R
        ) async throws -> R {
            try await _withTemporaryRecordSpace { space in
                let queryResult = try await space.execute(queryRequest).value
                
                return try body(queryResult)
            }
        }

        public func executeSynchronously<R>(
            _ body: @escaping (Transaction) throws -> R
        ) throws -> R {
            try _withTemporaryRecordSpace { space in
                do {
                    let result = try space.nsManagedObjectContext.performAndWait {
                        let result = try body(Transaction(recordSpace: space))
                        
                        try space.nsManagedObjectContext.save()
                        
                        return result
                    }
                    
                    return result
                }
            }
        }
        
        private func _withTemporaryRecordSpace<R>(
            perform: (Database.RecordSpace) throws -> R
        ) throws -> R {
            let nsManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            
            nsManagedObjectContext.parent = recordSpace.nsManagedObjectContext
            
            let recordSpace = RecordSpace(
                databaseContext: recordSpace.databaseContext,
                managedObjectContext: nsManagedObjectContext,
                affectedStores: recordSpace.affectedStores
            )
            
            return try perform(recordSpace)
        }
        
        private func _withTemporaryRecordSpace<R>(
            perform: (Database.RecordSpace) async throws -> R
        ) async throws -> R {
            let nsManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            
            nsManagedObjectContext.parent = recordSpace.nsManagedObjectContext
            
            let recordSpace = RecordSpace(
                databaseContext: recordSpace.databaseContext,
                managedObjectContext: nsManagedObjectContext,
                affectedStores: recordSpace.affectedStores
            )
            
            return try await perform(recordSpace)
        }
    }
}
