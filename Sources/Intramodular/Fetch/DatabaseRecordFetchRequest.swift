//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX

public enum DatabaseZoneQueryPredicate<Context: DatabaseRecordContext>: Hashable {
    case related(to: Context.RecordID, byKey: String)
    case child(of: Context.RecordID)

    case _nsPredicate(NSPredicate)
}

public struct DatabazeZoneQueryRequest<Context: DatabaseRecordContext>: Hashable {
    public let recordType: Context.RecordType?
    public var predicate: DatabaseZoneQueryPredicate<Context>?
    public var sortDescriptors: [AnySortDescriptor]?
    public let zones: [Context.Zone.ID]?
    public let includesSubentities: Bool
    
    public let cursor: PaginationCursor?
    public let fetchLimit: FetchLimit?
    
    public init(
        recordType: Context.RecordType?,
        predicate: DatabaseZoneQueryPredicate<Context>?,
        sortDescriptors: [AnySortDescriptor]?,
        zones: [Context.Zone.ID]?,
        includesSubentities: Bool,
        cursor: PaginationCursor?,
        limit: FetchLimit?
    ) {
        self.recordType = recordType
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.zones = zones
        self.includesSubentities = includesSubentities
        self.cursor = cursor
        self.fetchLimit = limit
    }
}

extension DatabazeZoneQueryRequest {
    public struct Result {
        let records: [Context.Record]?
    }
}
