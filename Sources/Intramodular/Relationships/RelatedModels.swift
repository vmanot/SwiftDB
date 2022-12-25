//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

/// An collection of models related to an entity.
public struct RelatedModels<Model: Entity> {
    private struct _Required {
        let _SwiftDB_taskContext: _SwiftDB_TaskContext
        let recordProxy: _DatabaseRecordProxy
        let key: AnyCodingKey
    }
    
    private let _required: _Required?
    
    private var _SwiftDB_taskContext: _SwiftDB_TaskContext {
        get throws {
            try _required.unwrap()._SwiftDB_taskContext
        }
    }
    
    private var recordProxy: _DatabaseRecordProxy{
        get throws {
            try _required.unwrap().recordProxy
        }
    }
    
    private var key: AnyCodingKey {
        get throws {
            try _required.unwrap().key
        }
    }

    private init(_required: _Required?) {
        self._required = _required
    }
    
    init(
        _SwiftDB_taskContext: _SwiftDB_TaskContext,
        recordProxy: _DatabaseRecordProxy,
        key: AnyCodingKey
    ) {
        self.init(
            _required: .init(
                _SwiftDB_taskContext: _SwiftDB_taskContext,
                recordProxy: recordProxy,
                key: key
            )
        )
    }
}

extension RelatedModels {
    public mutating func insert(_ model: Model) {
        do {
            try recordProxy.decodeAndReencodeRelationship(forKey: key) { relationship in
                let metadata = try RecordInstanceMetadata.from(instance: model)
                
                try relationship.insert(metadata.recordID)
            }
        } catch {
            assertionFailure(error)
        }
    }
    
    public mutating func remove(_ model: Model) {
        do {
            try recordProxy.decodeAndReencodeRelationship(forKey: key) { relationship in
                let metadata = try RecordInstanceMetadata.from(instance: model)
                
                try relationship.remove(metadata.recordID)
            }
        } catch {
            assertionFailure(error)
        }
    }
}

// MARK: - Conformances -

extension RelatedModels: _EntityRelationshipToManyDestination {
    public typealias _DestinationEntityType = Model
    
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .many
    }
    
    public static func _uninitializedInstance() -> RelatedModels<Model> {
        .init(_required: nil)
    }
}
