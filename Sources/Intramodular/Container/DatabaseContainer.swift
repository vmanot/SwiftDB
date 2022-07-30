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
    func destroyAndRebuild() async throws
}

/// A container that encapsulates a database stack in your app.
public final class DatabaseContainer<Schema: SwiftDB.Schema>: @unchecked Sendable, _opaque_DatabaseContainer, ObservableObject
{
    public let cancellables = Cancellables()
    
    fileprivate let fileManager = FileManager.default
    fileprivate let name: String
    fileprivate let schema: DatabaseSchema
    fileprivate let location: URL?
    fileprivate let stateLocation: URL?
    fileprivate let applicationGroupID: String?
    fileprivate let cloudKitContainerIdentifier: String?
    
    fileprivate var database: _CoreData.Database
            
    public var mainContext: AnyDatabaseRecordContext {
        get throws {
            try database.viewContext.map(AnyDatabaseRecordContext.init).unwrap()
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
        self.stateLocation = location?.appendingPathComponent(name, conformingTo: .fileURL).appendingPathExtension(DatabaseStateFileFormat.pathExtension)
        self.applicationGroupID = applicationGroupID
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        
        var databaseState: _CoreData.Database.State?

        if let stateLocation = stateLocation {
            databaseState = try? JSONDecoder().decode(_CoreData.Database.State.self, from: Data(contentsOf: stateLocation))
        }
        
        self.database = try _CoreData.Database(
            schema: .init(schema),
            configuration: _CoreData.Database.Configuration(
                name: name,
                location: location,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: databaseState
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
        
        Task.detached(priority: .userInitiated) { @MainActor in
            if let stateLocation = self.stateLocation {
                try JSONEncoder().encode(self.database.state).write(to: stateLocation)
            }
        }
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
    
    @MainActor
    public func destroyAndRebuild() async throws {
        objectWillChange.send()
        
        try await database.delete()
        
        database = try _CoreData.Database(
            schema: database.schema,
            configuration: _CoreData.Database.Configuration(
                name: name,
                location: location,
                applicationGroupID: applicationGroupID,
                cloudKitContainerIdentifier: cloudKitContainerIdentifier
            ),
            state: .init()
        )
        
        try await load()
    }
}

extension View {
    /// Attaches a database container to this view.
    ///
    /// The view is disabled until the database container is initialized. This is intentionally done to prevent invalid access to an uninitialized database container.
    ///
    /// - Parameters:
    ///   - container: The database container to attach.
    public func databaseContainer<Schema>(
        _ container: DatabaseContainer<Schema>
    ) -> some View {
        modifier(AttachDatabaseContainer(container: container))
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

struct AttachDatabaseContainer<Schema: SwiftDB.Schema>: ViewModifier {
    @ObservedObject var container: DatabaseContainer<Schema>
    
    @State private var hasAttemptedInitialization: Bool = false
    
    func body(content: Content) -> some View {
        if let mainContext = try? container.mainContext {
            content
                .databaseRecordContext(mainContext)
                .environmentObject(container)
        } else {
            ZeroSizeView().onAppear {
                initializeContainerIfNecessary()
            }
            .background {
                PerformAction {
                    initializeContainerIfNecessary()
                }
            }
        }
    }
    
    private func initializeContainerIfNecessary() {
        guard !hasAttemptedInitialization else {
            return
        }
        
        Task(priority: .userInitiated) {
            try await container.load()
        }
        
        hasAttemptedInitialization = true
    }
}
