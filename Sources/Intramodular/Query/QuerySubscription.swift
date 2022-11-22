//
// Copyright (c) Vatsal Manot
//

import Combine
import Merge
import Swallow

public final class QuerySubscription<Model>: ObservableObject {
    private let base: AnyDatabaseQuerySubscription
    private var baseSubscription: AnyCancellable?

    @Published private(set) var results: [RecordSnapshot<Model>]?

    init(
        from base: AnyDatabaseQuerySubscription,
        context: _SwiftDB_TaskContext
    ) {
        self.base = base

        baseSubscription = base
            .tryMap({ try $0.map({ try RecordSnapshot<Model>(from: $0, context: context) }) })
            .receiveOnMainThread()
            .stopExecutionOnError()
            .sink { value in
                self.results = value

                self.objectWillChange.send()
            }
    }
}
