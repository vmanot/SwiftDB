//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Swallow

public enum DatabaseZoneQueryPredicate<Context: DatabaseRecordContext>: Hashable {
    case related(to: Context.RecordID, by: AnyCodingKey)
    
    case _nsPredicate(NSPredicate)
}

public struct DatabazeZoneQueryRequest<Context: DatabaseRecordContext>: Hashable {
    public struct Filters: Codable, Hashable {
        public let zones: [Context.Zone.ID]?
        public let recordType: Context.RecordType?
        public let includesSubentities: Bool
    }
    
    public var predicate: DatabaseZoneQueryPredicate<Context>?
    public var sortDescriptors: [AnySortDescriptor]?
    public var filters: Filters
    
    public let cursor: PaginationCursor?
    public let fetchLimit: FetchLimit?
    
    public init(
        predicate: DatabaseZoneQueryPredicate<Context>?,
        sortDescriptors: [AnySortDescriptor]?,
        filters: Filters,
        cursor: PaginationCursor?,
        limit: FetchLimit?
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.filters = filters
        self.cursor = cursor
        self.fetchLimit = limit
    }
}

extension DatabazeZoneQueryRequest {
    public struct Result {
        let records: [Context.Record]?
    }
}
