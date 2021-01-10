//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow
import SwiftUIX

public protocol _opaque_PersistentContainer: AnyProtocol {
    func _opaque_create(_: _opaque_Entity.Type) -> _opaque_Entity
}

public final class PersistentContainer<Schema: SwiftDB.Schema>: _opaque_PersistentContainer, CancellablesHolder, Identifiable, ObservableObject {
    public let cancellables = Cancellables()
    
    fileprivate let fileManager = FileManager.default
    fileprivate let schema: SchemaDescription
    fileprivate let applicationGroupID: String?
    fileprivate let cloudKitContainerIdentifier: String?
    
    @Published public private(set) var id = UUID()
    @Published public private(set) var base: NSPersistentContainer
    @Published public private(set) var viewContext: NSManagedObjectContext?
    
    public init(
        _ schema: Schema,
        applicationGroupID: String? = nil,
        cloudKitContainerIdentifier: String? = nil
    ) {
        self.schema = SchemaDescription(schema)
        self.applicationGroupID = applicationGroupID
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        
        if cloudKitContainerIdentifier == nil {
            self.base = NSPersistentContainer(
                name: schema.name,
                managedObjectModel: NSManagedObjectModel(self.schema)
            )
        } else {
            self.base = NSPersistentCloudKitContainer(
                name: schema.name,
                managedObjectModel: NSManagedObjectModel(self.schema)
            )
        }
        
        do {
            try loadPersistentStores()
        } catch {
            
        }
    }
    
    public convenience init(_ schema: Schema) {
        self.init(
            schema,
            applicationGroupID: nil,
            cloudKitContainerIdentifier: nil
        )
    }
}

extension PersistentContainer {
    public var sqliteStoreURL: URL? {
        guard let applicationGroupID = applicationGroupID else {
            return base.persistentStoreDescriptions.first?.url
        }
        
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupID)!.appendingPathComponent(schema.name + ".sqlite")
    }
    
    public var allStoreFiles: [URL] {
        var result: [URL] = []
        
        if let sqliteStoreURL = sqliteStoreURL {
            result.append(sqliteStoreURL.deletingLastPathComponent().appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist"))
            result.append(sqliteStoreURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            result.append(sqliteStoreURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            result.append(sqliteStoreURL.deletingLastPathComponent().appendingPathComponent(".\(schema.name)_SUPPORT/"))
            result.append(sqliteStoreURL)
        }
        
        return result
    }
}

extension PersistentContainer {
    public var arePersistentStoresLoaded: Bool {
        !base.persistentStoreCoordinator.persistentStores.isEmpty
    }
    
    func setupPersistentStoreDescription() throws {
        if let sqliteStoreURL = sqliteStoreURL {
            base.persistentStoreDescriptions = [.init(url: sqliteStoreURL)]
        }
        
        let description = try base.persistentStoreDescriptions.first.unwrap()
        
        if let cloudKitContainerIdentifier = cloudKitContainerIdentifier {
            description.cloudKitContainerOptions = .init(containerIdentifier: cloudKitContainerIdentifier)
            
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
    }
    
    private func loadPersistentStores() throws {
        try setupPersistentStoreDescription()
        
        base.loadPersistentStores()
            .map({
                self.base.persistentStoreCoordinator._SwiftDB_schemaDescription = self.schema
                
                self.base
                    .viewContext
                    .automaticallyMergesChangesFromParent = true
                
                self.viewContext = self.base.viewContext
            })
            .subscribe(in: cancellables)
    }
    
    public func save() {
        guard base.viewContext.hasChanges else {
            return
        }
        
        try! base.viewContext.save()
        
        objectWillChange.send()
    }
    
    public func deleteAllFiles() throws {
        allStoreFiles.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
    
    public func destroyAndRebuild() throws {
        try deleteAllFiles()
        
        viewContext = nil
        
        base.viewContext.rollback()
        base.viewContext.reset()
        
        try base.persistentStoreCoordinator.destroyAll()
        
        base = NSPersistentContainer(
            name: schema.name,
            managedObjectModel: NSManagedObjectModel(self.schema)
        )
        
        try loadPersistentStores()
    }
    
    public func deleteAll() throws {
        try fetchAllInstances().forEach({ try self.delete($0) })
    }
}

extension PersistentContainer {
    public func fetchAllInstances() throws -> [_opaque_Entity] {
        try base.viewContext.save()
        
        var result: [_opaque_Entity] = []
        
        for (name, type) in schema.entityNameToTypeMap {
            let instances = try! base.viewContext
                .fetch(NSFetchRequest<NSManagedObject>(entityName: name))
                .map({ type.value.init(_runtime_underlyingObject: $0) })
            
            result.append(contentsOf: instances)
        }
        
        return result
    }
}

// MARK: - API -

extension PersistentContainer {
    @discardableResult
    public func _opaque_create(_ type: _opaque_Entity.Type) -> _opaque_Entity {
        let type = type as _opaque_Entity.Type
        
        let entityDescription = base.managedObjectModel.entitiesByName[type.name]!
        let managedObjectClass = type.managedObjectClass.value as! NSManagedObject.Type
        let managedObject = managedObjectClass.init(entity: entityDescription, insertInto: viewContext)
        
        return type.init(_runtime_underlyingObject: managedObject)
    }
    
    @discardableResult
    public func create<Instance: Entity>(_ type: Instance.Type) -> Instance {
        let type = type as _opaque_Entity.Type
        
        let entityDescription = base.managedObjectModel.entitiesByName[type.name]!
        let managedObjectClass = type.managedObjectClass.value as! NSManagedObject.Type
        let managedObject = managedObjectClass.init(entity: entityDescription, insertInto: viewContext)
        
        return type.init(_runtime_underlyingObject: managedObject) as! Instance
    }
    
    public func fetchFirst<Instance: Entity>(_ type: Instance.Type) throws -> Instance? {
        let type = type as _opaque_Entity.Type
        
        let managedObjectClass = type.managedObjectClass.value as! NSManagedObject.Type
        
        guard let managedObject = try viewContext?.fetchFirst(managedObjectClass) else {
            return nil
        }
        
        return .some(type.init(_runtime_underlyingObject: managedObject) as! Instance)
    }
    
    public func delete(_ instance: _opaque_Entity) throws {
        try _CoreData.DatabaseRecordContext(
            managedObjectContext: try viewContext.unwrap(),
            affectedStores: nil
        ).delete(try instance._runtime_underlyingObject.unwrap() as! _CoreData.DatabaseRecordContext.Record)
    }
}

extension View {
    public func persistentContainer<Schema>(
        _ container: PersistentContainer<Schema>
    ) -> some View {
        self.environment(\.managedObjectContext, container.base.viewContext)
            .environment(\.schemaDescription, container.schema)
            .environmentObject(container)
    }
}

// MARK: - Helpers -

extension CodingUserInfoKey {
    fileprivate static let _SwiftDB_PersistentContainer = CodingUserInfoKey(rawValue: "_SwiftDB_PersistentContainer")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_PersistentContainer: _opaque_PersistentContainer! {
        get {
            self[._SwiftDB_PersistentContainer] as? _opaque_PersistentContainer
        } set {
            self[._SwiftDB_PersistentContainer] = newValue
        }
    }
}

extension JSONDecoder {
    public var persistentContainer: _opaque_PersistentContainer? {
        get {
            userInfo[._SwiftDB_PersistentContainer] as? _opaque_PersistentContainer
        } set {
            userInfo[._SwiftDB_PersistentContainer] = newValue
        }
    }
}
