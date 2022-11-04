//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

extension _CoreData {
    /// A description used to create and load a persistent store.
    public struct PersistentStoreDescription: Hashable {
        public private(set) var type: NSPersistentStoreType
        public private(set) var configuration: String?
        public private(set) var url: URL?
        public private(set) var options: [String: NSObject] = [:]
        public private(set) var isReadOnly: Bool = false
        public private(set) var timeout: TimeInterval
        public private(set) var sqlitePragmas: [String: NSObject] = [:]
        public private(set) var shouldAddStoreAsynchronously: Bool = false
        public private(set) var shouldMigrateStoreAutomatically: Bool = true
        public private(set) var shouldInferMappingModelAutomatically: Bool = true
    }
}

// MARK: - Auxiliary Implementation -

extension NSPersistentStoreDescription {
    public convenience init(_ description: _CoreData.PersistentStoreDescription) {
        self.init()
        
        type = description.type.rawValue
        configuration = description.configuration
        url = description.url
        
        for (key, option) in description.options {
            setOption(option, forKey: key)
        }
        
        isReadOnly = description.isReadOnly
        timeout = description.timeout
        
        for (pragma, value) in description.sqlitePragmas {
            setValue(value, forPragmaNamed: pragma)
        }
        
        shouldAddStoreAsynchronously = description.shouldAddStoreAsynchronously
        shouldMigrateStoreAutomatically = description.shouldMigrateStoreAutomatically
        shouldInferMappingModelAutomatically = description.shouldInferMappingModelAutomatically
    }
}
