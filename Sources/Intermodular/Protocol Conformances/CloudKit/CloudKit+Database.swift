//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Runtime
import Swallow

extension _CloudKit {
    public final class Database {
        public let runtime: DatabaseRuntime
        public let schema: DatabaseSchema?
        public let configuration: Configuration
        public let state: State
        
        internal let base: CKContainer
        internal var ckDatabase: CKDatabase
        
        public init(
            runtime: DatabaseRuntime,
            schema: DatabaseSchema?,
            configuration: Configuration,
            state: State
        ) throws {
            self.runtime = runtime
            self.schema = schema
            self.configuration = configuration
            self.state = state
            
            self.base = configuration.containerIdentifier.map({ CKContainer(identifier: $0) }) ?? .default()
            
            self.ckDatabase = try base.database(for: configuration.scope)
        }
        
        public init(container: CKContainer, scope: CKDatabase.Scope) throws {
            self.runtime = _DefaultDatabaseRuntime()
            self.schema = nil
            self.configuration = .init(
                containerIdentifier: container.containerIdentifier!,
                scope: scope
            )
            self.state = nil
            
            self.base = container
            self.ckDatabase = try base.database(for: scope)
        }
    }
}

extension _CloudKit.Database {
    public struct Configuration: Codable {
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
    
    public struct State: Codable, ExpressibleByNilLiteral {
        @NSKeyedArchived
        public var serverChangeToken: CKServerChangeToken?
        
        public init(nilLiteral: Void) {
            
        }
    }
}

extension _CloudKit.Database: Database {
    public typealias RecordContext = _CloudKit.DatabaseRecordContext
    public typealias Zone = _CloudKit.DatabaseZone
    
    public var capabilities: [DatabaseCapability] {
        []
    }
    
    public func fetchAllAvailableZones() -> AnyTask<[Zone], Error> {
        let operation = CKFetchRecordZonesOperation()
        
        let result = PassthroughTask<[Zone], Error>()
        
        operation.database = ckDatabase
        operation.fetchRecordZonesCompletionBlock = { recordZonesByZoneID, operationError in
            if let operationError = operationError {
                result.send(.error(operationError))
            } else {
                let zones = Array((recordZonesByZoneID ?? [:]).values).map({ Zone(recordZone: $0) })
                
                result.send(.success(zones))
            }
        }
        
        return result.handleEvents(receiveStart: { operation.start() }).eraseToAnyTask()
    }
    
    public func fetchZone(named name: String) -> AnyTask<Zone, Error> {
        fatalError()
    }
    
    public func recordContext(forZones zones: [Zone]?) throws -> RecordContext {
        .init(container: base, database: ckDatabase, zones: try zones.unwrap())
    }
    
    public func delete() -> AnyTask<Void, Error> {
        fatalError(reason: .unimplemented)
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
