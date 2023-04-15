//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// A subscription to a database query.
///
/// A query subscription is also a `Publisher` that can be subscribed to.
public protocol DatabaseQuerySubscription: Publisher where Output == [Database.Record], Error == Swift.Error {
    associatedtype Database: SwiftDB.Database
}
