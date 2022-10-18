//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public final class AnyDatabaseQuerySubscription: DatabaseQuerySubscription {
    private let base: any DatabaseQuerySubscription
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.eraseObjectWillChangePublisher()
    }
    
    public init<Subscription: DatabaseQuerySubscription>(erasing subscription: Subscription) {
        self.base = subscription
    }
}
