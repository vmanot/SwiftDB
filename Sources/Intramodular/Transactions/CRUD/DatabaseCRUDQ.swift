//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public protocol DatabaseCRUDQ {
    func create<Instance: Entity>(_ entityType: Instance.Type) throws -> Instance
    func queryExecutionTask<Model>(for request: QueryRequest<Model>) -> AnyTask<QueryRequest<Model>.Output, Error>
    func querySubscription<Model>(for request: QueryRequest<Model>) throws -> QuerySubscription<Model>
    func delete<Instance: Entity>(_ instance: Instance) throws
}
