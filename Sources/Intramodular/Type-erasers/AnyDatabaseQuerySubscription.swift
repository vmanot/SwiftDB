//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public final class AnyDatabaseQuerySubscription: DatabaseQuerySubscription {
    public typealias Database = AnyDatabase
    
    public typealias Output = [Database.Record]
    public typealias Failure = Swift.Error
    
    private let base: AnyPublisher<[Database.Record], Swift.Error>
    
    public init<Publisher: DatabaseQuerySubscription>(erasing publisher: Publisher) {
        self.base = publisher.eraseError().map {
            $0.map({ AnyDatabaseRecord(erasing: $0) })
        }
        .eraseToAnyPublisher()
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        base.receive(subscriber: subscriber)
    }
}
