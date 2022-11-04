//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public final class QuerySubscription<Model>: ObservableObject {
    private let base: AnyDatabaseQuerySubscription
    private var baseSubscription: AnyCancellable?
    
    init(from base: AnyDatabaseQuerySubscription) {
        self.base = base
        
        baseSubscription = base.stopExecutionOnError().sink { _ in
            self.objectWillChange.send()
        }
    }
}
