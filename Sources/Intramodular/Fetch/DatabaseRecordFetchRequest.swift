//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX

public struct DatabaseFetchRequest<Context: DatabaseRecordContext>: Hashable {
    public let recordType: Context.RecordType?
    @NSKeyedArchived
    public var predicate: NSPredicate?
    public var sortDescriptors: [SortDescriptor]?
    public let zones: [Context.Zone.ID]?
    public let includesSubentities: Bool
    
    public let cursor: PaginationCursor?
    public let limit: PaginationLimit?
}

extension DatabaseFetchRequest {
    public struct Result {
        let records: [Context.Record]?
    }
}
