//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Merge
import Swallow

public final class PersistentContainer: Identifiable, ObservableObject {
    private let cancellables = Cancellables()
    
    @Published public private(set) var id = UUID()
    @Published public private(set) var base: NSPersistentContainer
    @Published public private(set) var viewContext: NSManagedObjectContext?
    
    @Published private var applicationGroupID: String?
    @Published private var cloudKitContainerIdentifier: String?
    
    public init(name: String) {
        self.base = NSPersistentContainer(name: name)
    }
    
    public init<S: Schema>(_ schema: S) {
        self.base = NSPersistentContainer(name: schema.name, managedObjectModel: .init(schema))
    }
}

extension PersistentContainer {
    public func createObject<E: Entity>(_ type: E.Type) -> NSManagedObject {
        let entityDescription = base.managedObjectModel.entitiesByName[type.name]!
        let classType = type.managedObjectClass.value as! NSManagedObject.Type
        
        return classType.init(entity: entityDescription, insertInto: viewContext)
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
    
    public func saveViewContext() {
        if base.viewContext.hasChanges {
            try! base.viewContext.save()
        }
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
