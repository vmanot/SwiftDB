//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

/// An collection of models related to an entity.
public struct RelatedModels<Model: Entity> {
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .many
    }

    let _SwiftDB_taskContext: _SwiftDB_TaskContext?

    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext
    ) {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
    }

    public init(noRelatedModels: Void) {
        self._SwiftDB_taskContext = nil
    }
}

extension RelatedModels: EntityRelatable {
    public typealias RelatableEntityType = Model
}

extension RelatedModels {
    public mutating func insert(_ model: Model) {
        TODO.unimplemented
    }

    public mutating func remove(_ model: Model) {
        TODO.unimplemented
    }
}
