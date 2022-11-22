//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Swallow

public enum DatabaseZoneQueryPredicate<Database: SwiftDB.Database>: Hashable, NSPredicateConvertible {
    case related(to: Database.Record.ID, by: AnyCodingKey)
    
    case _nsPredicate(NSPredicate)
    
    public init(_ predicate: NSPredicate) {
        self = ._nsPredicate(predicate)
    }
    
    public func toNSPredicate(context: NSPredicateConversionContext) throws -> NSPredicate {
        switch self {
            case .related:
                throw Never.Reason.unsupported
            case ._nsPredicate(let predicate):
                return predicate
        }
    }
}

public struct DatabaseZoneQueryRequest<Database: SwiftDB.Database>: Hashable {
    public struct Filters: Hashable {
        public let zones: [Database.Zone.ID]?
        public let recordIDs: [Database.Record.ID]?
        public var recordTypes: Set<Database.Record.RecordType>
        public let includesSubentities: Bool
    }

    public typealias Predicate = DatabaseZoneQueryPredicate<Database>

    public var filters: Filters
    public var predicate: Predicate?
    public var sortDescriptors: [AnySortDescriptor]?
    public let cursor: PaginationCursor?
    public let fetchLimit: FetchLimit?
    
    public init(
        filters: Filters,
        predicate: DatabaseZoneQueryPredicate<Database>?,
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
        let records: [Database.Record]?
    }
}

// MARK: - Auxiliary -

extension DatabaseZoneQueryRequest where Database == AnyDatabase {
    func _cast<T>(to type: DatabaseZoneQueryRequest<T>.Type) throws -> DatabaseZoneQueryRequest<T> {
        .init(
            filters: try filters._cast(to: T.ZoneQueryRequest.Filters.self),
            predicate: try predicate?._cast(to: T.ZoneQueryRequest.Predicate.self),
            sortDescriptors: sortDescriptors,
            cursor: cursor,
            limit: fetchLimit
        )
    }
}

extension DatabaseZoneQueryRequest.Filters where Database == AnyDatabase {
    func _cast<T>(to type: DatabaseZoneQueryRequest<T>.Filters.Type) throws -> DatabaseZoneQueryRequest<T>.Filters {
        try DatabaseZoneQueryRequest<T>.Filters(
            zones: zones?.map({ try cast($0.base, to: T.Zone.ID.self) }),
            recordIDs: try recordIDs?.map({ try $0._cast(to: T.Record.ID.self) }),
            recordTypes: Set(recordTypes.map({ try $0._cast(to: T.Record.RecordType.self) })),
            includesSubentities: includesSubentities
        )
    }
}

extension DatabaseZoneQueryRequest.Result where Database == AnyDatabase {
    init<T>(_erasing request: DatabaseZoneQueryRequest<T>.Result) {
        self.init(records: request.records?.map({ AnyDatabaseRecord(erasing: $0) }))
    }
}

extension DatabaseZoneQueryPredicate where Database == AnyDatabase {
    init<T>(
        from predicate: DatabaseZoneQueryPredicate<T>
    ) {
        switch predicate {
            case .related(let recordID, let fieldName):
                self = .related(to: AnyDatabaseRecord.ID(base: recordID), by: fieldName)
            case ._nsPredicate(let predicate):
                self = ._nsPredicate(predicate)
        }
    }

    func _cast<T>(to type: DatabaseZoneQueryPredicate<T>.Type) throws -> DatabaseZoneQueryPredicate<T> {
        switch self {
            case .related(let recordID, let fieldName):
                return .related(to: try recordID._cast(to: T.Record.ID.self), by: fieldName)
            case ._nsPredicate(let predicate):
                return ._nsPredicate(predicate)
        }
    }
}

extension DatabaseZoneQueryRequest where Database == AnyDatabase {
    public init<Model>(
        from queryRequest: QueryRequest<Model>,
        databaseContext: Database.Context
    )  throws {
        let recordTypes: [AnyDatabaseRecord.RecordType]

        if Model.self == Any.self {
            recordTypes = try databaseContext.schema.entities.map({ try databaseContext.schemaAdaptor.recordType(for: $0.id) })
        } else {
            let entity = try databaseContext.schema.entity(forModelType: Model.self).unwrap().id

            recordTypes = [try databaseContext.schemaAdaptor.recordType(for: entity)]
        }

        try self.init(
            filters: .init(
                zones: queryRequest.scope.zones,
                recordIDs: queryRequest.scope.records,
                recordTypes: Set(recordTypes),
                includesSubentities: true
            ),
            predicate: queryRequest.predicate.map({ predicate in
                DatabaseZoneQueryPredicate(
                    try predicate.toNSPredicate(
                        context: .init(
                            expressionConversionContext: .init(
                                keyPathConversionStrategy: .custom(databaseContext.runtime.convertEntityKeyPathToString),
                                keyPathPrefix: nil
                            )
                        )
                    )
                )
            }),
            sortDescriptors: queryRequest.sortDescriptors,
            cursor: nil,
            limit: queryRequest.fetchLimit
        )
    }
}

