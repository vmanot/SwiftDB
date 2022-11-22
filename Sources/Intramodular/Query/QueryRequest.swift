//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import Swallow

/// A description of search criteria used to retrieve data from a persistent store.
public struct QueryRequest<Model> {
    public var predicate: AnyPredicate?
    public var sortDescriptors: [AnySortDescriptor]?
    public var fetchLimit: FetchLimit?
    public var scope: Scope

    @_disfavoredOverload
    public init(
        predicate: AnyPredicate?,
        sortDescriptors: [AnySortDescriptor]?,
        fetchLimit: FetchLimit?,
        scope: Scope
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
        self.scope = scope
    }

    public init(
        predicate: Predicate<Model>?,
        sortDescriptors: [AnySortDescriptor]?,
        fetchLimit: FetchLimit?,
        scope: Scope
    ) {
        self.init(
            predicate: predicate.map(AnyPredicate.init),
            sortDescriptors: sortDescriptors,
            fetchLimit: nil,
            scope: scope
        )
    }
}

extension QueryRequest {
    public struct Scope: ExpressibleByNilLiteral {
        public let zones: [AnyDatabase.Zone.ID]?
        public let records: [AnyDatabase.Record.ID]?

        public init(zones: [AnyDatabase.Zone.ID]? = nil, records: [AnyDatabase.Record.ID]? = nil) {
            self.zones = zones
            self.records = records
        }

        public init(nilLiteral: ()) {
            self.init(zones: nil, records: nil)
        }
    }

    public struct Output {
        public typealias Results = [Model]

        public let results: Results
    }
}
