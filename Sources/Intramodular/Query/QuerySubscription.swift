//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public final class QuerySubscription<Model>: ObservableObject {
    private let base: AnyDatabaseQuerySubscription
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.eraseObjectWillChangePublisher()
    }
    
    init(from base: AnyDatabaseQuerySubscription) {
        self.base = base
    }
}
