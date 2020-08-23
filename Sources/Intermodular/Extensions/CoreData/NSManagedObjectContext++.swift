//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Swift

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
    
    public func delete<Objects: RandomAccessCollection>(_ objects: Objects) where Objects.Element: NSManagedObject {
        for object in objects {
            delete(object)
        }
    }
}
