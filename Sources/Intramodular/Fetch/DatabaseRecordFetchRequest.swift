//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX

public struct DatabaseFetchRequest<Context: DatabaseRecordContext>: Codable, Hashable {
    public let recordType: Context.RecordType?
    @NSKeyedArchived
    public var predicate: NSPredicate?
    public var sortDescriptors: [SortDescriptor]?
    public let zones: [Context.Zone.ID]?
    public let includesSubentities: Bool
    
    public let cursor: PaginationCursor?
    public let fetchLimit: FetchLimit?
    
    public init(
        recordType: Context.RecordType?,
        predicate: NSPredicate?,
        sortDescriptors: [SortDescriptor]?,
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

extension DatabaseFetchRequest {
    public struct Result {
        let records: [Context.Record]?
    }
}
