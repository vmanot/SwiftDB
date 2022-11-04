//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

/// A persistent store type.
public enum NSPersistentStoreType {
    case binaryStore
    case inMemory
    case sqlite
    
    public var rawValue: String {
        switch self {
            case .binaryStore:
                return NSBinaryStoreType
            case .inMemory:
                return NSInMemoryStoreType
            case .sqlite:
                return NSSQLiteStoreType
        }
    }
}
