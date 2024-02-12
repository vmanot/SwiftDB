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
                        case .set(let value):
                            switch value {
                                case .toOne(let value):
                                    try managedObject._setToOne(value?.nsManagedObjectID, forKey: key)
                                case .toUnorderedMany(let value):
                                    try managedObject._setToUnorderedMany(
                                        value.map({ $0.nsManagedObjectID }),
                                        forKey: key
                                    )
                                case .toOrderedMany(let value):
                                    try managedObject._setToOrderedMany(
                                        value.map({ $0.nsManagedObjectID }),
                                        forKey: key
                                    )
                            }
                        case .apply(let value):
                            switch value {
                                case .toOne(let value):
                                    if let update = value.update {
                                        try managedObject._setToOne(
                                            update.newValue?.nsManagedObjectID,
                                            forKey: key
                                        )
                                    }
                                case .toUnorderedMany(let value):
                                    try managedObject._applyToUnorderedManyDiff(
                                        value.map({ $0.nsManagedObjectID }),
                                        forKey: key
                                    )
                                case .toOrderedMany(let value):
                                    try managedObject._applyToOrderedManyDiff(
                                        value.map({ $0.nsManagedObjectID }),
                                        forKey: key
                                    )
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
                try await space.nsManagedObjectContext.perform {
                    try body(Transaction(recordSpace: space))
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
                try space.nsManagedObjectContext.performAndWait {
                    try body(Transaction(recordSpace: space))
                }
            }
        }
        
        private func _withTemporaryRecordSpace<R>(
            perform: (Database.RecordSpace) throws -> R
        ) throws -> R {
            let nsManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            
            nsManagedObjectContext.parent = recordSpace.nsManagedObjectContext
            
            let temporarySpace = RecordSpace(
                databaseContext: recordSpace.databaseContext,
                managedObjectContext: nsManagedObjectContext,
                affectedStores: recordSpace.affectedStores
            )
            
            let result = try perform(temporarySpace)
            
            try temporarySpace.nsManagedObjectContext.performAndWait {
                try temporarySpace.nsManagedObjectContext.save()
            }
            
            try recordSpace.nsManagedObjectContext.save()
            
            return result
        }
        
        private func _withTemporaryRecordSpace<R>(
            perform: (Database.RecordSpace) async throws -> R
        ) async throws -> R {
            let nsManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            
            nsManagedObjectContext.parent = recordSpace.nsManagedObjectContext
            
            let temporarySpace = RecordSpace(
                databaseContext: recordSpace.databaseContext,
                managedObjectContext: nsManagedObjectContext,
                affectedStores: recordSpace.affectedStores
            )
            
            let result = try await perform(recordSpace)
            
            try await temporarySpace.save()
            try await recordSpace.save()
            
            return result
        }
    }
}
