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

        public func updateRecord(
            _ recordID: _CoreData.DatabaseRecord.ID,
            with update: RecordUpdate
        ) throws {
            let record = self.record(for: recordID)
            let managedObject = record.rawObject
            let key = update.key

            switch update.payload {
                case .data(let payload):
                    if let value = payload.value {
                        if let value = payload.value as? NSAttributeCoder {
                            try value.encode(to: managedObject, forKey: key)
                        } else if let value = value as? Codable {
                            try value.encode(to: managedObject, forKey: key)
                        } else {
                            TODO.unimplemented
                        }
                    } else {
                        try managedObject._unsafeEncodeValue(nil, forKey: key)
                    }
                case .relationship(let payload):
                    switch payload {
                        case .toOne(let payload):
                            switch payload {
                                case .set(let recordID):
                                    try managedObject._setRelated(objectID: recordID?.nsManagedObjectID, forKey: key)
                            }
                        case .toUnorderedMany(let payload):
                            switch payload {
                                case .insert(let recordID):
                                    try managedObject._insertRelated(objectID: recordID.nsManagedObjectID, forKey: key)
                                case .remove(let recordID):
                                    try managedObject._removeRelated(objectID: recordID.nsManagedObjectID, forKey: key)
                                case .set(let recordIDs):
                                    try managedObject._setRelated(objectIDs: Set(recordIDs.map({ $0.nsManagedObjectID })), forKey: key)
                            }
                        case .toOrderedMany(let payload):
                            switch payload {
                                case .insert(let recordID):
                                    try managedObject._insertRelated(objectID: recordID.nsManagedObjectID, forKey: key)
                                case .remove(let recordID):
                                    try managedObject._removeRelated(objectID: recordID.nsManagedObjectID, forKey: key)
                                case .set(let recordIDs):
                                    try managedObject._setRelated(objectIDs: recordIDs.map({ $0.nsManagedObjectID }) as Array, forKey: key)
                            }
                    }
            }
        }

        public func executeSynchronously(
            _ request: Database.ZoneQueryRequest
        ) throws -> Database.ZoneQueryRequest.Result {
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

        public func delete(_ recordID: Database.Record.ID) throws {
            try recordSpace.delete(recordID)
        }

        private func record(for id: _CoreData.Database.Record.ID) -> _CoreData.Database.Record {
            .init(rawObject: recordSpace.nsManagedObjectContext.object(with: id.nsManagedObjectID))
        }
    }
}

extension _CoreData.Database {
    public struct TransactionExecutor: DatabaseTransactionExecutor {
        public typealias Database = _CoreData.Database

        let recordSpace: RecordSpace

        init(recordSpace: RecordSpace) {
            self.recordSpace = recordSpace
        }

        public func execute<R>(_ body: @escaping (Transaction) throws -> R) async throws -> R {
            try await _withTemporaryRecordSpace { space in
                do {
                    let result = try await space.nsManagedObjectContext.perform {
                        let result = try body(Transaction(recordSpace: space))

                        try space.nsManagedObjectContext.save()

                        return result
                    }

                    return result
                }
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
