//
// Copyright (c) Vatsal Manot
//

import Swallow

extension DatabaseCRUDQ {
    /// Create an entity instance.
    @discardableResult
    public func create<Instance: Entity>(
        _ type: Instance.Type,
        body: (Instance) throws -> Void
    ) throws -> Instance {
        let record = try create(type)

        try body(record)

        return record
    }
}
