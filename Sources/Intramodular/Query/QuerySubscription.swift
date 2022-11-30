//
// Copyright (c) Vatsal Manot
//

import Combine
import Merge
import Swallow

/// A subscription to a database query.
///
/// This subscription is a publisher that replays the last published element upon subscription.
public final class QuerySubscription<Model>: ObservableObject {
    private let base: AnyDatabaseQuerySubscription
    private var baseSubscription: AnyCancellable?

    private let resultsPublisher = ReplaySubject<Output, Error>(bufferSize: 1)

    @Published private(set) var results: [RecordSnapshot<Model>]?

    init(
        from base: AnyDatabaseQuerySubscription,
        context: _SwiftDB_TaskContext
    ) {
        self.base = base

        baseSubscription = base
            .tryMap({ try $0.map({ try RecordSnapshot<Model>(from: $0, context: context) }) })
            .stopExecutionOnError()
            .sink { completion in
                switch completion {
                    case .finished:
                        self.resultsPublisher.send(completion: .finished)
                    case .failure(let error):
                        self.resultsPublisher.send(completion: .failure(error))
                }
            } receiveValue: { value in
                self.resultsPublisher.send(value)

                MainThreadScheduler.shared.schedule {
                    self.results = value
                }
            }
    }
}

// MARK: - Conformances -

extension QuerySubscription: Publisher {
    public typealias Output = [RecordSnapshot<Model>]
    public typealias Failure = Swift.Error

    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        resultsPublisher.receive(subscriber: subscriber)
    }
}
