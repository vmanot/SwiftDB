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
    
    public func delete(_ recordID: AnyDatabaseRecord.ID) throws {
        try base._opaque_delete(recordID)
    }
    
    @discardableResult
    public func save() -> AnyTask<Void, SaveError> {
        base._opaque_save()
    }
}

// MARK: - Auxiliary -

private extension DatabaseRecordSpace {
    func _opaque_createRecord(
        withConfiguration configuration: AnyDatabaseRecordSpace.RecordConfiguration
    ) throws -> AnyDatabaseRecord {
        let record = try createRecord(
            withConfiguration: RecordConfiguration(
                recordType: configuration.recordType?._cast(to: Record.RecordType.self),
                recordID: configuration.recordID.map({ try $0._cast(to: Record.ID.self) }),
                zone: configuration.zone.map({ try cast($0.base, to: Zone.self) })
            )
        )
        
        return .init(erasing: record)
    }
    
    func _opaque_execute(
        _ request: AnyDatabase.ZoneQueryRequest
    ) -> AnyTask<AnyDatabase.ZoneQueryRequest.Result, Error> {
        do {
            return try execute(request._cast(to: Database.ZoneQueryRequest.self))
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
            
    func _opaque_delete(_ record: AnyDatabaseRecord.ID) throws {
        let _record = try record._cast(to: Record.ID.self)
        
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
}
