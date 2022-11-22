//
// Copyright (c) Vatsal Manot
//

@preconcurrency import CloudKit
import Merge
import Runtime
import Swallow

extension _CloudKit {
    public final class Database {
        public let schema: _Schema?
        public let configuration: Configuration
        public let state: State
        public let context: Context
        
        internal let ckContainer: CKContainer
        internal var ckDatabase: CKDatabase

        public init(
            runtime: _SwiftDB_Runtime,
            schema: _Schema?,
            configuration: Configuration,
            state: State?
        ) throws {
            self.schema = schema
            self.configuration = configuration
            self.state = state ?? .init()
            self.context = .init(runtime: runtime, schema: try schema.unwrap(), schemaAdaptor: .init())

            self.ckContainer = configuration.containerIdentifier.map({ CKContainer(identifier: $0) }) ?? .default()
            self.ckDatabase = try ckContainer.database(for: configuration.scope)
        }
    }
}

extension _CloudKit.Database {
    public struct Configuration: Codable, Sendable {
        public let containerIdentifier: String?
        public let scope: CKDatabase.Scope

        public init(
            containerIdentifier: String?,
            scope: CKDatabase.Scope
        ) {
            self.containerIdentifier = containerIdentifier
            self.scope = scope
        }
    }

    public struct State: Codable, Equatable, Sendable {
        @NSKeyedArchived
        public var serverChangeToken: CKServerChangeToken?
    }
}

extension _CloudKit.Database: Database {
    public typealias SchemaAdaptor = _CloudKit.DatabaseSchemaAdaptor
    public typealias Zone = _CloudKit.DatabaseZone
    public typealias Record = _CloudKit.DatabaseRecord
    public typealias RecordSpace = _CloudKit.DatabaseRecordSpace

    public func fetchAllAvailableZones() -> AnyTask<[Zone], Error> {
        TODO.unimplemented

        /*let operation = CKFetchRecordZonesOperation()

        let result = PassthroughTask<[Zone], Error>()

        operation.database = ckDatabase
        operation.fetchRecordZonesCompletionBlock = { recordZonesByZoneID, operationError in
            if let operationError = operationError {
                result.send(status: .error(operationError))
            } else {
                let zones = Array((recordZonesByZoneID ?? [:]).values).map({ Zone(recordZone: $0) })

                result.send(status: .success(zones))
            }
        }

        return result.handleEvents(receiveStart: { operation.start() }).eraseToAnyTask()*/
    }
    
    public func querySubscription(
        for request: ZoneQueryRequest
    ) throws -> QuerySubscription {
        TODO.unimplemented
    }
    
    public func transactionExecutor() throws -> TransactionExecutor {
        TODO.unimplemented
    }

    public func recordSpace(forZones zones: [Zone]?) throws -> RecordSpace {
        .init(parent: self, zones: try zones.unwrap())
    }

    public func delete() -> AnyTask<Void, Error> {
        TODO.unimplemented
    }
}

extension _CloudKit.Database: Identifiable {
    public var id: String? {
        configuration.containerIdentifier
    }
}

extension _CloudKit.Database: Named {
    public var name: String {
        ""
    }
}

// MARK: - Auxiliary -

extension _CloudKit.Database {
    public final class QuerySubscription: DatabaseQuerySubscription {
        public typealias Database = _CloudKit.Database
        
        public typealias Output = [Database.Record]
        public typealias Failure = Error
        
        fileprivate init() {
            TODO.unimplemented
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, [Database.Record] == S.Input {
            fatalError()
        }
    }
}
