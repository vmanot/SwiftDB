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

public struct DatabaseZoneQueryRequest<Context: DatabaseRecordContext>: Hashable {
    public struct Filters: Codable, Hashable {
        public let zones: [Context.Zone.ID]?
        public let recordTypes: Set<Context.RecordType>
        public let includesSubentities: Bool
    }
    
    public var filters: Filters
    public var predicate: DatabaseZoneQueryPredicate<Context>?
    public var sortDescriptors: [AnySortDescriptor]?
    
    public let cursor: PaginationCursor?
    public let fetchLimit: FetchLimit?
    
    public init(
        filters: Filters,
        predicate: DatabaseZoneQueryPredicate<Context>?,
        sortDescriptors: [AnySortDescriptor]?,
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

extension DatabaseZoneQueryRequest {
    public struct Result {
        let records: [Context.Record]?
    }
}
