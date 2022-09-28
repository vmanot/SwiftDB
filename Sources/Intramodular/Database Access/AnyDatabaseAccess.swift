//
// Copyright (c) Vatsal Manot
//

import API
import Diagnostics
import Merge
import Swallow

public struct AnyDatabaseAccess {
    private let _databaseContext: AnyDatabase.Context?
    private let _recordContext: AnyDatabase.RecordContext?
    
    var databaseContext: AnyDatabase.Context {
        get throws {
            try _databaseContext.unwrap()
        }
    }
    
    var recordContext: AnyDatabase.RecordContext {
        get throws {
            try _recordContext.unwrap()
        }
    }
    
    public var isInitialized: Bool {
        _databaseContext != nil && _recordContext != nil
    }
    
    public init(
        databaseContext: AnyDatabase.Context?,
        recordContext: AnyDatabase.RecordContext?
    ) {
        self._databaseContext = databaseContext
        self._recordContext = recordContext
    }
}

extension AnyDatabaseAccess {
    public func willChangePublisher() -> AnyObjectWillChangePublisher {
        self._recordContext?.objectWillChange ?? .empty
    }
}

extension AnyDatabaseAccess {
    public func transact<T>(_ body: () throws -> T) throws -> T {
        let result = try body()
        
        try recordContext.save()
        
        return result
    }
    
    public func transact<T>(_ body: () async throws -> T) async throws -> T {
        let result = try await body()
        
        try await recordContext.save()
        
        return result
    }
}

extension AnyDatabaseAccess {
    public func _create(_ entityType: any Entity.Type) throws -> any Entity {
        let entity = try databaseContext.schema.entity(forModelType: entityType).unwrap().id
        
        let record = try recordContext.createRecord(
            withConfiguration: .init(
                recordType: databaseContext.schemaAdaptor.recordType(for: entity),
                recordID: nil,
                zone: nil
            ),
            context: .init()
        )
        
        return try entityType.init(from: record)
    }
    
    public func create<Instance: Entity>(_ entity: Instance.Type) throws -> Instance {
        try cast(_create(entity as (any Entity.Type)), to: Instance.self)
    }
    
    /// Create an entity instance.
    @discardableResult
    public func create<Instance: Entity>(
        _ type: Instance.Type,
        body: (Instance) throws -> Void
    ) throws -> Instance {
        let record = try create(type)
        
        try body(record)
        
        return record
    }
}
