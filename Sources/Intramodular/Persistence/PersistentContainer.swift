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
    
    private(set) var database: _CoreData.Database
    
    public init(
        name: String,
        schema: Schema,
        applicationGroupID: String? = nil,
        cloudKitContainerIdentifier: String? = nil
    ) throws {
        self.database = try _CoreData.Database(
            schema: .init(schema),
            configuration: _CoreData.Database.Configuration(
                name: name,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: nil
        )
        
        self.schema = DatabaseSchema(schema)
        self.applicationGroupID = applicationGroupID
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
    }
    
    public convenience init(name: String, schema: Schema) throws {
        try self.init(
            name: name,
            schema: schema,
            applicationGroupID: nil,
            cloudKitContainerIdentifier: nil
        )
    }
}

extension PersistentContainer {
    public var arePersistentStoresLoaded: Bool {
        !database.nsPersistentContainer.persistentStoreCoordinator.persistentStores.isEmpty
    }
    
    public func save() throws {
        try database
            .recordContext(forZones: nil)
            .save()
            .successPublisher
            .toResultPublisher()
            .publish(to: objectWillChange)
            .subscribe(in: cancellables)
    }
    
    public func destroyAndRebuild() throws {
        try deleteAll()
        
        if database.nsPersistentContainer.viewContext.hasChanges {
            database.nsPersistentContainer.viewContext.rollback()
            database.nsPersistentContainer.viewContext.reset()
        }
        
        try database.delete().successPublisher.subscribeAndWaitUntilDone().get()
        
        database = try .init(
            schema: database.schema,
            configuration: database.configuration,
            state: nil
        )
        
        database.fetchAllZones()
    }
    
    public func deleteAll() throws {
        try fetchAllInstances().forEach({ try self.delete($0) })
    }
}

extension PersistentContainer {
    public func fetchAllInstances() throws -> [_opaque_Entity] {
        if database.nsPersistentContainer.viewContext.hasChanges {
            try database.nsPersistentContainer.viewContext.save()
        }
        
        var result: [_opaque_Entity] = []
        
        for (name, type) in schema.entityNameToTypeMap {
            let instances = try! database.nsPersistentContainer.viewContext
                .fetch(NSFetchRequest<NSManagedObject>(entityName: name))
                .map {
                    type.value.init(
                        _underlyingDatabaseRecord: _CoreData.DatabaseRecord(base: $0),
                        context: DatabaseRecordCreateContext<_CoreData.DatabaseRecordContext>()
                    )
                }
            
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
            _underlyingDatabaseRecord: try database.recordContext(forZones: nil).createRecord(
                withConfiguration: .init(
                    recordType: type.name,
                    recordID: nil,
                    zone: nil
                ),
                context: .init()
            ),
            context: DatabaseRecordCreateContext<_CoreData.DatabaseRecordContext>()
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
            .map {
                $0.map {
                    Instance(
                        _underlyingDatabaseRecord: $0,
                        context: DatabaseRecordCreateContext<_CoreData.DatabaseRecordContext>()
                    )
                }
            }
            .eraseError()
            .eraseToAnyPublisher()
            .convertToTask()
    }
    
    public func first<Instance: Entity>(
        _ type: Instance.Type
    ) throws -> Instance? {
        try fetchFirst(type).successPublisher.subscribeAndWaitUntilDone().get()
    }
    
    public func delete(_ instance: _opaque_Entity) throws {
        let context = try database.recordContext(forZones: nil)
        
        try context.delete(try instance._underlyingDatabaseRecord.unwrap() as! _CoreData.DatabaseRecordContext.Record)
        
        try context.save().successPublisher.subscribeAndWaitUntilDone().get()
    }
}

extension View {
    public func persistentContainer<Schema>(
        _ container: PersistentContainer<Schema>
    ) -> some View {
        self.environment(\.managedObjectContext, container.database.nsPersistentContainer.viewContext)
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
