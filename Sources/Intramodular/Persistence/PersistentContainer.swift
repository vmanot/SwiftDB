//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow
import SwiftUIX

public protocol _opaque_PersistentContainer: AnyProtocol {
    func _opaque_create(_: _opaque_Entity.Type) throws -> _opaque_Entity
    
    func create<Instance: Entity>(_ type: Instance.Type) throws -> Instance
}

public final class PersistentContainer<Schema: SwiftDB.Schema>: _opaque_PersistentContainer, CancellablesHolder, Identifiable, ObservableObject {
    public let cancellables = Cancellables()
    
    fileprivate let fileManager = FileManager.default
    fileprivate let schema: DatabaseSchema
    fileprivate let applicationGroupID: String?
    fileprivate let cloudKitContainerIdentifier: String?
    
    @Published public private(set) var id = UUID()
    @Published public private(set) var base: NSPersistentContainer
    @Published public private(set) var viewContext: NSManagedObjectContext?
    
    let database: _CoreData.Database
    
    public init(
        _ schema: Schema,
        applicationGroupID: String? = nil,
        cloudKitContainerIdentifier: String? = nil
    ) throws {
        self.database = try _CoreData.Database(
            schema: .init(schema),
            configuration: _CoreData.Database.Configuration(
                name: schema.name,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: nil
        )
        
        self.schema = DatabaseSchema(schema)
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
    }
    
    public convenience init(_ schema: Schema) throws {
        try self.init(
            schema,
            applicationGroupID: nil,
            cloudKitContainerIdentifier: nil
        )
    }
}

extension PersistentContainer {
    public var arePersistentStoresLoaded: Bool {
        !base.persistentStoreCoordinator.persistentStores.isEmpty
    }
    
    
    public func save() throws {
        try database
            .recordContext(forZones: nil)
            .save()
            .onStatus(.success) { status in
                self.objectWillChange.send()
            }
            .subscribe(in: cancellables)
    }
    
    /*    public func destroyAndRebuild() throws {
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
     }*/
    
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
                .map({ type.value.init(_runtime_underlyingDatabaseRecord: _CoreData.DatabaseRecord(base: $0)) })
            
            result.append(contentsOf: instances)
        }
        
        return result
    }
}

// MARK: - API -

extension PersistentContainer {
    @discardableResult
    public func _opaque_create(_ type: _opaque_Entity.Type) throws -> _opaque_Entity {
        type.init(
            _runtime_underlyingDatabaseRecord: try database.recordContext(forZones: nil).createRecord(
                withConfiguration: .init(
                    recordType: type.name,
                    recordID: nil,
                    zone: nil
                ),
                context: .init()
            )
        )
    }
    
    @discardableResult
    public func create<Instance: Entity>(_ type: Instance.Type) throws -> Instance {
        try cast(try _opaque_create(type as _opaque_Entity.Type), to: Instance.self)
    }
    
    public func fetchFirst<Instance: Entity>(
        _ type: Instance.Type
    ) throws -> AnyTask<Instance?, Error> {
        try database
            .recordContext(forZones: nil)
            .execute(.init(recordType: type.name, predicate: nil, sortDescriptors: nil, zones: nil, includesSubentities: true, cursor: nil, limit: .cursor(.offset(1))))
            .successPublisher
            .map({ $0.records?.first })
            .map({ $0.map(Instance.init(_runtime_underlyingDatabaseRecord:)) })
            .eraseError()
            .eraseToAnyPublisher()
            .convertToTask()
    }
    
    public func delete(_ instance: _opaque_Entity) throws {
        try _CoreData.DatabaseRecordContext(
            managedObjectContext: try viewContext.unwrap(),
            affectedStores: nil
        )
        .delete(try instance._runtime_underlyingDatabaseRecord.unwrap() as! _CoreData.DatabaseRecordContext.Record)
    }
}

extension View {
    public func persistentContainer<Schema>(
        _ container: PersistentContainer<Schema>
    ) -> some View {
        self.environment(\.managedObjectContext, container.base.viewContext)
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
