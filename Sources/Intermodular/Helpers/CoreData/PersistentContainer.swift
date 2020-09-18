//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Merge
import Swallow
import SwiftUIX

public final class PersistentContainer<Schema: SwiftDB.Schema>: AnyProtocol, CancellablesHolder, Identifiable, ObservableObject {
    public let cancellables = Cancellables()
    
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
        
        loadPersistentStores()
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
            return nil
        }
        
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupID)!.appendingPathComponent(base.name + ".sqlite")
    }
}

extension PersistentContainer {
    public var arePersistentStoresLoaded: Bool {
        !base.persistentStoreCoordinator.persistentStores.isEmpty
    }
    
    func setupPersistentStoreDescription() {
        if let sqliteStoreURL = sqliteStoreURL {
            base.persistentStoreDescriptions = [.init(url: sqliteStoreURL)]
        }
        
        guard let description = base.persistentStoreDescriptions.first else {
            fatalError("Could not retrieve a persistent store description.")
        }
        
        if let cloudKitContainerIdentifier = cloudKitContainerIdentifier {
            description.cloudKitContainerOptions = .init(containerIdentifier: cloudKitContainerIdentifier)
            
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
    }
    
    private func loadPersistentStores() {
        setupPersistentStoreDescription()
        
        base.loadPersistentStores()
            .map({
                self.base.persistentStoreCoordinator._SwiftDB_schemaDescription = self.schema
                
                self.base
                    .viewContext
                    .automaticallyMergesChangesFromParent = true
                
                self.viewContext = self.base.viewContext
            })
            .subscribe(storeIn: cancellables)
    }
        
    public func save() {
        if base.viewContext.hasChanges {
            try! base.viewContext.save()
        }
        
        objectWillChange.send()
    }
    
    public func destroyAndRebuild() throws {
        viewContext = nil
        
        base.viewContext.rollback()
        base.viewContext.reset()
        
        try base.persistentStoreCoordinator.destroyAll()
        
        base = NSPersistentContainer(name: base.name)
        
        loadPersistentStores()
    }
}

// MARK: - API -

extension PersistentContainer {
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
    
    public func delete<Instance: Entity>(_ instance: Instance) {
        viewContext!.delete(instance._runtime_underlyingObject!)
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
