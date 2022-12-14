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
    let recordProxy: _DatabaseRecordProxy?
    let key: AnyCodingKey?

    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordProxy: _DatabaseRecordProxy,
        key: AnyCodingKey
    ) {
        self._SwiftDB_taskContext = _SwiftDB_taskContext
        self.recordProxy = recordProxy
        self.key = key
    }
    
    public init(noRelatedModels: Void) {
        self._SwiftDB_taskContext = nil
        self.recordProxy = nil
        self.key = nil
    }
}

extension RelatedModels: EntityRelatable {
    public typealias RelatableEntityType = Model
}

extension RelatedModels {
    public mutating func insert(_ model: Model) {
        do {
            let metadata = try RecordInstanceMetadata.from(instance: model)
        } catch {
            assertionFailure(error)
        }
    }
    
    public mutating func remove(_ model: Model) {
        TODO.unimplemented
    }
}
