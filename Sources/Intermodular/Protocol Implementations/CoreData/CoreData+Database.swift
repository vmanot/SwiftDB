//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData {
    public final class Database {
        public struct Configuration: Codable {
            public let name: String
            
            public init(name: String) {
                self.name = name
            }
        }
        
        public struct State: Codable, ExpressibleByNilLiteral {
            public init(nilLiteral: Void) {
                
            }
        }
        
        public let schema: SchemaDescription?
        public let configuration: Configuration
        public let state: State
        
        fileprivate let base: NSPersistentContainer
        
        public init(
            schema: SchemaDescription?,
            configuration: Configuration,
            state: State
        ) {
            self.schema = schema
            self.configuration = configuration
            self.state = state
            
            if let schema = schema {
                self.base = .init(name: configuration.name, managedObjectModel: .init(schema))
            } else {
                self.base = .init(name: configuration.name)
            }
        }
        
        public init(container: NSPersistentContainer) {
            self.schema = nil // FIXME!!!Ω
            self.configuration = .init(name: container.name)
            self.state = nil
            self.base = container
        }
    }
}

extension _CoreData.Database: Database {
    public typealias RecordContext = _CoreData.DatabaseRecordContext
    
    public var capabilities: [DatabaseCapability] {
        []
    }
    
    public func fetchAllZones() -> AnyTask<[Zone], Error> {
        if base.persistentStoreCoordinator.persistentStores.isEmpty {
            return base.loadPersistentStores().map {
                self.base
                    .persistentStoreCoordinator
                    .persistentStores
                    .map({ _CoreData.Zone(base: $0) })
            }
            .convertToTask()
        } else {
            return .just(.success(base.persistentStoreCoordinator.persistentStores.map({ Zone(base: $0) })))
        }
    }
    
    public func fetchZone(named name: String) -> AnyTask<Zone, Error> {
        fetchAllZones()
            .successPublisher
            .tryMap({ try $0.filter({ $0.name == name }).first.unwrap() })
            .eraseError()
            .convertToTask()
    }
    
    public func recordContext(forZones _: [Zone]) -> RecordContext {
        .init(base: base.viewContext)
    }
}

extension _CoreData.Database: Identifiable {
    public var id: String {
        name
    }
}

extension _CoreData.Database: Named {
    public var name: String {
        base.name
    }
}
