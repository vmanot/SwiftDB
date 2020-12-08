//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import Task

extension _CoreData {
    final class Database {
        private let container: NSPersistentContainer
        
        init(container: NSPersistentContainer) {
            self.container = container
        }
    }
}

extension _CoreData.Database: Database {
    typealias Zone = _CoreData.Zone
    typealias ObjectContext = _CoreData.DatabaseObjectContext
    
    var id: String {
        container.name
    }
    
    var name: String {
        container.name
    }
    
    func fetchAllZones() -> AnyTask<[Zone], Error> {
        if container.persistentStoreCoordinator.persistentStores.isEmpty {
            return container.loadPersistentStores().map {
                self.container
                    .persistentStoreCoordinator
                    .persistentStores
                    .map({ _CoreData.Zone(base: $0) })
            }
            .eraseToTask()
        } else {
            return .just(.success(container.persistentStoreCoordinator.persistentStores.map({ Zone(base: $0) })))
        }
    }
    
    func fetchZone(named name: String) -> AnyTask<Zone, Error> {
        fetchAllZones()
            .successPublisher
            .tryMap({ try $0.filter({ $0.name == name }).first.unwrap() })
            .eraseError()
            .eraseToTask()
    }
    
    func context(forZones _: [Zone]) -> ObjectContext {
        .init(base: container.viewContext)
    }
}
