//
// Copyright (c) Vatsal Manot
//

import Swallow

public final class AnyDatabaseRecordContext: DatabaseRecordContext {
    public typealias Zone = AnyDatabaseZone
    public typealias Record = AnyDatabaseRecord
    public typealias RecordType = AnyDatabaseRecord.RecordType
    public typealias RecordID = AnyDatabaseRecord.ID
    public typealias RecordConfiguration = DatabaseRecordConfiguration<AnyDatabaseRecordContext>
    
    private let baseBox: _AnyDatabaseRecordContextBoxBase
    
    public init<RecordContext: DatabaseRecordContext>(_ recordContext: RecordContext) {
        self.baseBox = _AnyDatabaseRecordContextBox(recordContext)
    }
    
    public func createRecord(
        withConfiguration configuration: DatabaseRecordConfiguration<AnyDatabaseRecordContext>,
        context: RecordCreateContext
    ) throws -> AnyDatabaseRecord {
        try baseBox.createRecord(
            withConfiguration: configuration,
            context: context
        )
    }

    public func instantiate<Model: Entity>(
        _ type: Model.Type,
        from record: AnyDatabaseRecord
    ) throws -> Model {
        try baseBox.instantiate(type, from: record)
    }
    
    public func recordID(from record: AnyDatabaseRecord) throws -> AnyDatabaseRecord.ID {
        try baseBox.recordID(from: record)
    }
    
    public func zone(for record: AnyDatabaseRecord) throws -> AnyDatabaseZone? {
        try baseBox.zone(for: record)
    }
    
    public func zoneQueryRequest<Model>(from queryRequest: QueryRequest<Model>) throws -> ZoneQueryRequest {
        try baseBox.zoneQueryRequest(from: queryRequest)
    }
    
    public func execute(_ request: ZoneQueryRequest) -> AnyTask<ZoneQueryRequest.Result, Error> {
        baseBox.execute(request)
    }
    
    public func delete(_ record: AnyDatabaseRecord) throws {
        try baseBox.delete(record)
    }
    
    public func save() -> AnyTask<Void, SaveError> {
        baseBox.save()
    }
}

// MARK: - Underlying Implementation -

class _AnyDatabaseRecordContextBoxBase {
    func createRecord(
        withConfiguration configuration: DatabaseRecordConfiguration<AnyDatabaseRecordContext>,
        context: AnyDatabaseRecordContext.RecordCreateContext
    ) throws -> AnyDatabaseRecord {
        fatalError()
    }

    func instantiate<Model: Entity>(
        _ type: Model.Type,
        from record: AnyDatabaseRecord
    ) throws -> Model {
       fatalError()
    }

    func recordID(from record: AnyDatabaseRecord) throws -> AnyDatabaseRecord.ID {
        fatalError()
    }
    
    func zone(for record: AnyDatabaseRecord) throws -> AnyDatabaseZone? {
        fatalError()
    }
    
    func zoneQueryRequest<Model>(
        from queryRequest: QueryRequest<Model>
    ) throws -> AnyDatabaseRecordContext.ZoneQueryRequest {
        fatalError()
    }
    
    func execute(
        _ request: AnyDatabaseRecordContext.ZoneQueryRequest
    ) -> AnyTask<AnyDatabaseRecordContext.ZoneQueryRequest.Result, Error> {
        fatalError()
    }
    
    func delete(_ record: AnyDatabaseRecord) throws {
        fatalError()
    }
    
    func save() -> AnyTask<Void, AnyDatabaseRecordContext.SaveError> {
        fatalError()
    }
}

final class _AnyDatabaseRecordContextBox<Base: DatabaseRecordContext>: _AnyDatabaseRecordContextBoxBase {
    let base: Base
    
    init(_ base: Base) {
        self.base = base
    }
    
    override func createRecord(
        withConfiguration configuration: DatabaseRecordConfiguration<AnyDatabaseRecordContext>,
        context: AnyDatabaseRecordContext.RecordCreateContext
    ) throws -> AnyDatabaseRecord {
        let _record = try base.createRecord(
            withConfiguration: .init(
                recordType: Base.RecordType(configuration.recordType.rawValue).unwrap(),
                recordID: configuration.recordID.map({ try cast($0.base, to: Base.RecordID.self) }),
                zone: configuration.zone.map({ try cast($0.base, to: Base.Zone.self) })
            ),
            context: .init()
        )
        
        return .init(base: _record)
    }

    override func instantiate<Model: Entity>(
        _ type: Model.Type,
        from record: AnyDatabaseRecord
    ) throws -> Model {
        let _record = try cast(record.base, to: Base.Record.self)

        return try base.instantiate(type, from: _record)
    }
    
    override func recordID(from record: AnyDatabaseRecord) throws -> AnyDatabaseRecord.ID {
        let _record = try cast(record.base, to: Base.Record.self)
        
        return AnyDatabaseRecord.ID(base: try base.recordID(from: _record))
    }
    
    override func zone(for record: AnyDatabaseRecord) throws -> AnyDatabaseZone? {
        let _record = try cast(record.base, to: Base.Record.self)
        
        return try base.zone(for: _record).map(AnyDatabaseZone.init)
    }
    
    override func zoneQueryRequest<Model>(
        from queryRequest: QueryRequest<Model>
    ) throws -> AnyDatabaseRecordContext.ZoneQueryRequest {
        let _zoneQueryRequest = try base.zoneQueryRequest(from: queryRequest)
        
        return .init(
            filters: .init(
                zones: _zoneQueryRequest.filters.zones?.map({ AnyDatabaseZone.Identifier(base: $0) }),
                recordTypes: Set(_zoneQueryRequest.filters.recordTypes.map({ AnyDatabaseRecord.RecordType(from: $0) })),
                includesSubentities: _zoneQueryRequest.filters.includesSubentities
            ),
            predicate: _zoneQueryRequest.predicate.map(DatabaseZoneQueryPredicate.init(from:)),
            sortDescriptors: _zoneQueryRequest.sortDescriptors,
            cursor: _zoneQueryRequest.cursor,
            limit: _zoneQueryRequest.fetchLimit
        )
    }
    
    override func execute(
        _ request: AnyDatabaseRecordContext.ZoneQueryRequest
    ) -> AnyTask<AnyDatabaseRecordContext.ZoneQueryRequest.Result, Error> {
        do {
            return try base.execute(translateZoneQueryRequest(request))
                .successPublisher
                .map { result in
                    AnyDatabaseRecordContext.ZoneQueryRequest.Result(records: result.records?.map({ AnyDatabaseRecord(base: $0) }))
                }
                .convertToTask()
        } catch {
            return .failure(error)
        }
    }
    
    override func delete(_ record: AnyDatabaseRecord) throws {
        let _record = try cast(record.base, to: Base.Record.self)
        
        return try base.delete(_record)
    }
    
    override func save() -> AnyTask<Void, AnyDatabaseRecordContext.SaveError> {
        base.save()
            .successPublisher
            .mapError { error in
                AnyDatabaseRecordContext.SaveError(mergeConflicts: error.mergeConflicts?.map({ DatabaseRecordMergeConflict(source: AnyDatabaseRecord(base: $0.source)) }))
            }
            .convertToTask()
    }
    
    private func translateZoneQueryRequest(
        _ request: AnyDatabaseRecordContext.ZoneQueryRequest
    ) throws -> Base.ZoneQueryRequest {
        .init(
            filters: try translateZoneQueryRequestFilters(request.filters),
            predicate: try translateZoneQueryRequestPredicate(request.predicate),
            sortDescriptors: request.sortDescriptors,
            cursor: request.cursor,
            limit: request.fetchLimit
        )
    }
    
    private func translateZoneQueryRequestFilters(
        _ filters: DatabaseZoneQueryRequest<AnyDatabaseRecordContext>.Filters
    ) throws -> DatabaseZoneQueryRequest<Base>.Filters {
        try DatabaseZoneQueryRequest<Base>.Filters(
            zones: filters.zones?.map({ try cast($0.base, to: Base.Zone.ID.self) }),
            recordTypes: Set(filters.recordTypes.map({ try Base.RecordType($0.rawValue).unwrap() })),
            includesSubentities: filters.includesSubentities
        )
    }
    
    private func translateZoneQueryRequestPredicate(
        _ predicate: DatabaseZoneQueryPredicate<AnyDatabaseRecordContext>?
    ) throws -> DatabaseZoneQueryPredicate<Base>? {
        guard let predicate = predicate else {
            return nil
        }
        
        switch predicate {
            case .related(let recordID, let fieldName):
                return .related(to: try cast(recordID.base, to: Base.RecordID.self), by: fieldName)
            case ._nsPredicate(let predicate):
                return ._nsPredicate(predicate)
        }
    }
}

// MARK: - Auxiliary Implementation -

extension DatabaseZoneQueryPredicate where Context == AnyDatabaseRecordContext {
    fileprivate init<T: DatabaseRecordContext>(
        from predicate: DatabaseZoneQueryPredicate<T>
    ) {
        switch predicate {
            case .related(let recordID, let fieldName):
                self = .related(to: AnyDatabaseRecord.ID(base: recordID), by: fieldName)
            case ._nsPredicate(let predicate):
                self = ._nsPredicate(predicate)
        }
    }
}
