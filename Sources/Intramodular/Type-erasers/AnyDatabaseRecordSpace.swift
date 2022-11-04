//
// Copyright (c) Vatsal Manot
//

import Swallow
import Merge

public final class AnyDatabaseRecordSpace: DatabaseRecordSpace, Sendable {
    public typealias Database = AnyDatabase
    public typealias Zone = AnyDatabaseZone
    public typealias Record = AnyDatabaseRecord
    public typealias QuerySubscription = AnyDatabaseQuerySubscription
    
    private let base: any DatabaseRecordSpace
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.eraseObjectWillChangePublisher()
    }
    
    private init(base: any DatabaseRecordSpace) {
        self.base = base
    }
    
    public convenience init<RecordSpace: DatabaseRecordSpace>(erasing recordSpace: RecordSpace) {
        self.init(base: recordSpace)
    }
    
    public func createRecord(
        withConfiguration configuration: RecordConfiguration
    ) throws -> AnyDatabaseRecord {
        try base._opaque_createRecord(
            withConfiguration: configuration
        )
    }
    
    public func execute(_ request: Database.ZoneQueryRequest) -> AnyTask<Database.ZoneQueryRequest.Result, Error> {
        base._opaque_execute(request)
    }
    
    public func querySubscription(for request: Database.ZoneQueryRequest) throws -> AnyDatabaseQuerySubscription {
        try base._opaque_querySubscription(for: request)
    }

    public func delete(_ record: AnyDatabaseRecord) throws {
        try base._opaque_delete(record)
    }
    
    @discardableResult
    public func save() -> AnyTask<Void, SaveError> {
        base._opaque_save()
    }
}

// MARK: - Auxiliary Implementation -

private extension DatabaseRecordSpace {
    func _opaque_createRecord(
        withConfiguration configuration: AnyDatabaseRecordSpace.RecordConfiguration
    ) throws -> AnyDatabaseRecord {
        let record = try createRecord(
            withConfiguration: RecordConfiguration(
                recordType: configuration.recordType?._cast(to: Record.RecordType.self),
                recordID: configuration.recordID.map({ try cast($0.base, to: Record.ID.self) }),
                zone: configuration.zone.map({ try cast($0.base, to: Zone.self) })
            )
        )
        
        return .init(erasing: record)
    }
    
    func _opaque_execute(
        _ request: AnyDatabase.ZoneQueryRequest
    ) -> AnyTask<AnyDatabase.ZoneQueryRequest.Result, Error> {
        do {
            return try execute(translateZoneQueryRequest(request))
                .successPublisher
                .map { result in
                    AnyDatabase.ZoneQueryRequest.Result(
                        records: result.records?.map({ AnyDatabaseRecord(erasing: $0) })
                    )
                }
                .convertToTask()
        } catch {
            return .failure(error)
        }
    }
    
    func _opaque_querySubscription(
        for request: AnyDatabase.ZoneQueryRequest
    ) throws -> AnyDatabaseQuerySubscription {
        try .init(erasing: querySubscription(for: translateZoneQueryRequest(request)))
    }
        
    func _opaque_delete(_ record: AnyDatabaseRecord) throws {
        let _record = try record._cast(to: Record.self)
        
        return try delete(_record)
    }
    
    func _opaque_save() -> AnyTask<Void, AnyDatabaseRecordSpace.SaveError> {
        save()
            .successPublisher
            .mapError { error in
                AnyDatabaseRecordSpace.SaveError(
                    description: error.description,
                    mergeConflicts: error.mergeConflicts?.map({ DatabaseRecordMergeConflict(source: AnyDatabaseRecord(erasing: $0.source)) })
                )
            }
            .convertToTask()
    }
    
    private func translateZoneQueryRequest(
        _ request: AnyDatabase.ZoneQueryRequest
    ) throws -> Database.ZoneQueryRequest {
        .init(
            filters: try translateZoneQueryRequestFilters(request.filters),
            predicate: try translateZoneQueryRequestPredicate(request.predicate),
            sortDescriptors: request.sortDescriptors,
            cursor: request.cursor,
            limit: request.fetchLimit
        )
    }
    
    private  func translateZoneQueryRequestFilters(
        _ filters: DatabaseZoneQueryRequest<AnyDatabase>.Filters
    ) throws -> DatabaseZoneQueryRequest<Database>.Filters {
        try DatabaseZoneQueryRequest.Filters(
            zones: filters.zones?.map({ try cast($0.base, to: Zone.ID.self) }),
            recordTypes: Set(filters.recordTypes.map({ try Record.RecordType($0.description).unwrap() })),
            includesSubentities: filters.includesSubentities
        )
    }
    
    private func translateZoneQueryRequestPredicate(
        _ predicate: DatabaseZoneQueryPredicate<AnyDatabase>?
    ) throws -> DatabaseZoneQueryPredicate<Database>? {
        guard let predicate = predicate else {
            return nil
        }
        
        switch predicate {
            case .related(let recordID, let fieldName):
                return .related(to: try cast(recordID.base, to: Record.ID.self), by: fieldName)
            case ._nsPredicate(let predicate):
                return ._nsPredicate(predicate)
        }
    }
}

extension DatabaseZoneQueryPredicate where Database == AnyDatabase {
    fileprivate init<T: DatabaseRecordSpace>(
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
