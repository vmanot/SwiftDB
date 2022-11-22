//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public struct Zone: DatabaseZone, Identifiable {
        public struct ID: Codable, Hashable {
            let fileURL: URL
                        
            init(_fileURL: URL) {
                self.fileURL = _fileURL
            }
            
            init(from store: NSPersistentStore) {
                fileURL = store.url!
            }
            
            init(from description: NSPersistentStoreDescription) {
                fileURL = description.url!
            }
        }
        
        let nsPersistentStoreDescription: NSPersistentStoreDescription
        
        public let id: ID
        public let name: String?
        public let fileURL: URL?

        init(persistentStoreDescription: NSPersistentStoreDescription) throws {
            let fileURL = persistentStoreDescription.url
            
            self.nsPersistentStoreDescription = persistentStoreDescription
            self.id = .init(from: persistentStoreDescription)
            self.name = try persistentStoreDescription.configuration
            self.fileURL = fileURL
        }
    }
}

extension _CoreData.Database.Zone: FolderEnclosable {
    public var topLevelFileContents: [URL.PathComponent] {
        guard let fileURL = fileURL else {
            return []
        }
        
        var result: [URL] = []
        
        let externalStorageFolderName = ".\(fileURL.deletingPathExtension().lastPathComponent)_SUPPORT"
        
        result.append(fileURL.deletingLastPathComponent().appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist"))
        result.append(fileURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
        result.append(fileURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
        result.append(fileURL.deletingLastPathComponent().appendingPathComponent(externalStorageFolderName, isDirectory: true))
        result.append(fileURL)
        
        return result.map({ URL.PathComponent(rawValue: $0.lastPathComponent) })
    }
}
