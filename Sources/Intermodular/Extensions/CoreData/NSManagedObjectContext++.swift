//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Swallow

extension NSManagedObjectContext {
    public func performAsynchronously<T>(_ body: @escaping () throws -> T) -> Future<T, Error> {
        return Future { receive in
            self.perform {
                receive(.init { try body() })
            }
        }
    }
}

extension NSManagedObjectContext {
    public func fetchFirst<Object: NSManagedObject>(_ type: Object.Type) throws -> Object? {
        try fetch(NSFetchRequest<Object>(entityName: type.entity().name.unwrap()).then {
            $0.fetchLimit = 1
        }).first
    }
    
    public func fetchAll<Object: NSManagedObject>(_ type: Object.Type) throws -> [Object] {
        try self
            .fetch(NSFetchRequest<NSManagedObject>(entityName: type.entity().name.unwrap()))
            .map {
                try cast($0, to: Object.self)
            }
    }
    
    public func delete<Objects: RandomAccessCollection>(_ objects: Objects) where Objects.Element: NSManagedObject {
        for object in objects {
            delete(object)
        }
    }
    
    public func deleteAll<Object: NSManagedObject>(_ type: Object.Type) throws {
        try execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: type.entity().name.unwrap())))
    }
}
