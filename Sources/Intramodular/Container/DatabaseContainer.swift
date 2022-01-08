//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow
import SwiftUIX

/// An opaque mirror for `DatabaseContainer`.
protocol _opaque_DatabaseContainer: _opaque_ObservableObject {
    var mainContext: AnyDatabaseRecordContext { get throws }
    
    func load() async throws
    func save() async throws
    
    func fetchAllInstances() async throws -> [Any]
    func deleteAllInstances() async throws
    func destroyAndRebuild() async throws
}

/// A container that encapsulates a database stack in your app.
public final class DatabaseContainer<Schema: SwiftDB.Schema>: _opaque_DatabaseContainer, ObservableObject
{
    public let cancellables = Cancellables()
    
    fileprivate let fileManager = FileManager.default
    fileprivate let name: String
    fileprivate let schema: DatabaseSchema
    fileprivate let location: URL?
    fileprivate let applicationGroupID: String?
    fileprivate let cloudKitContainerIdentifier: String?
    
    fileprivate var database: _CoreData.Database
    
    public var isLoaded: Bool {
        !database.nsPersistentContainer.persistentStoreCoordinator.persistentStores.isEmpty
    }

    private var _mainContext: AnyDatabaseRecordContext?

    public var mainContext: AnyDatabaseRecordContext {
        get throws {
            if let _mainContext = _mainContext {
                return _mainContext
            } else {
                _mainContext = try AnyDatabaseRecordContext(database.viewContext.unwrap())

                return try _mainContext.unwrap()
            }
        }
    }
    
    public init(
        name: String,
        schema: Schema,
        location: URL? = nil,
        applicationGroupID: String? = nil,
        cloudKitContainerIdentifier: String? = nil
    ) throws {
        self.name = name
        self.schema = try DatabaseSchema(schema)
        self.location = location
        self.applicationGroupID = applicationGroupID
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        
        self.database = try _CoreData.Database(
            schema: .init(schema),
            configuration: _CoreData.Database.Configuration(
                name: name,
                location: location,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: nil
        )
    }
    
    public convenience init(name: String, schema: Schema) throws {
        try self.init(
            name: name,
            schema: schema,
            applicationGroupID: nil,
            cloudKitContainerIdentifier: nil
        )
    }
    
    public func load() async throws {
        _ = try await database.fetchAllAvailableZones()
        
        await MainActor.run {
            objectWillChange.send()
        }
    }
    
    public func save() async throws {
        try await database
            .recordContext(forZones: nil)
            .save()
    }

    public func fetchAllInstances() throws -> [Any] {
        var result: [_opaque_Entity] = []
        
        for (name, type) in schema.entityNameToTypeMap {
            let instances = try! database.nsPersistentContainer.viewContext
                .fetch(NSFetchRequest<NSManagedObject>(entityName: name))
                .map {
                    try type.value.init(
                        _underlyingDatabaseRecord: _CoreData.DatabaseRecord(base: $0)
                    )
                }
            
            result.append(contentsOf: instances)
        }
        
        return result
    }
    
    public func deleteAllInstances() async throws {
        let allInstances = try fetchAllInstances()
        
        for instance in allInstances {
            guard let instance = instance as? _opaque_Entity else {
                assertionFailure()
                
                continue
            }

            try await mainContext._opaque_delete(instance)
        }
    }
    
    public func destroyAndRebuild() async throws {
        try await database.delete()
        
        await MainActor.run {
            objectWillChange.send()
        }
        
        database = try _CoreData.Database(
            schema: database.schema,
            configuration: _CoreData.Database.Configuration(
                name: name,
                location: location,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: nil
        )
        
        try await load()
    }
}

extension View {
    public func databaseContainer<Schema>(
        _ container: DatabaseContainer<Schema>
    ) -> some View {
        self
            .environment(
                \.managedObjectContext,
                 container.database.nsPersistentContainer.viewContext
            )
            .environment(\.databaseRecordContext, try? container.mainContext)
            .environmentObject(container)
    }
}

// MARK: - Auxiliary Implementation -

extension CodingUserInfoKey {
    fileprivate static let _SwiftDB_PersistentContainer = CodingUserInfoKey(rawValue: "_SwiftDB_PersistentContainer")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_PersistentContainer: _opaque_DatabaseContainer! {
        get {
            self[._SwiftDB_PersistentContainer] as? _opaque_DatabaseContainer
        } set {
            self[._SwiftDB_PersistentContainer] = newValue
        }
    }
}
