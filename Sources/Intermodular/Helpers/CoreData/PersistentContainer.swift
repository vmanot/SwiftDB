//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Merge
import Swallow
import SwiftUIX

public final class PersistentContainer<Schema: SwiftDB.Schema>: Identifiable, ObservableObject {
    let cancellables = Cancellables()
    let schemaDescription: SchemaDescription
    
    @Published public private(set) var id = UUID()
    @Published public private(set) var base: NSPersistentContainer
    @Published public private(set) var viewContext: NSManagedObjectContext?
    
    @Published private var applicationGroupID: String?
    @Published private var cloudKitContainerIdentifier: String?
    
    public init(_ schema: Schema) {
        self.schemaDescription = .init(schema)
        self.base = NSPersistentContainer(name: schema.name, managedObjectModel: .init(schemaDescription))
        
        loadPersistentStores()
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
        }
    }
    
    func loadPersistentStores() {
        base.loadPersistentStores()
            .map({
                self.base.persistentStoreCoordinator._SwiftDB_schemaDescription = self.schemaDescription
                
                self.base
                    .viewContext
                    .automaticallyMergesChangesFromParent = true
                
                self.viewContext = self.base.viewContext
            })
            .subscribe(storeIn: cancellables)
    }
}

extension PersistentContainer {
    public func loadViewContext() {
        setupPersistentStoreDescription()
        loadPersistentStores()
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
        
        loadViewContext()
    }
}

extension PersistentContainer {
    public func applicationGroupID(_ id: String) -> PersistentContainer {
        then({ $0.applicationGroupID = id })
    }
    
    public func cloudKitContainerIdentifier(_ id: String) -> PersistentContainer {
        then({ $0.cloudKitContainerIdentifier = id })
    }
}

// MARK: - API -

extension PersistentContainer {
    @discardableResult
    public func create<Instance: Entity>(_ type: Instance.Type) -> Instance {
        let entityDescription = base.managedObjectModel.entitiesByName[type.name]!
        let managedObjectType = type.managedObjectClass.value as! NSManagedObject.Type
        let managedObject = managedObjectType.init(entity: entityDescription, insertInto: viewContext)
        
        return Instance(_runtime_underlyingObject: managedObject)!
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
            .environment(\.schemaDescription, container.schemaDescription)
            .environmentObject(container)
    }
}
