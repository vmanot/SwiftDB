//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

/// An collection of models related to an entity.
public struct RelatedModels<Model: Entity> {
    private struct _Required {
        let recordProxy: _DatabaseRecordProxy
        let key: AnyCodingKey
    }
    
    private let _required: _Required?
    
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
    
    private var relationship: RelatedDatabaseRecordIdentifiers<AnyDatabase> {
        get throws {
            try recordProxy.decodeRelationship(forKey: key)
        }
    }
    
    public var isEmpty: Bool {
        false // FIXME!!!
    }
    
    private init(_required: _Required?) {
        self._required = _required
    }
    
    init(
        recordProxy: _DatabaseRecordProxy,
        key: AnyCodingKey
    ) {
        self.init(
            _required: .init(
                recordProxy: recordProxy,
                key: key
            )
        )
    }
}

extension RelatedModels {
    public var count: Int {
        try! relationship._toCollection().count
    }
    
    public func insert(_ model: Model) {
        do {
            try recordProxy.decodeAndReencodeRelationship(forKey: key) { relationship in
                let metadata = try RecordInstanceMetadata.from(instance: model)
                
                try relationship.insert(metadata.recordID)
            }
        } catch {
            assertionFailure(error)
        }
    }
    
    public func remove(_ model: Model) {
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

// MARK: - Conformances

extension RelatedModels: _EntityRelationshipToManyDestination {
    public typealias _DestinationEntityType = Model
    
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .many
    }
    
    public init(_relationshipPropertyAccessor: EntityPropertyAccessor) throws {
        let accessor = try cast(_relationshipPropertyAccessor, to: (any _EntityPropertyAccessor).self)
        
        if let recordProxy = accessor._underlyingRecordProxy {
            self.init(
                _required: _Required(
                    recordProxy: recordProxy,
                    key: try accessor.key
                )
            )
        } else {
            self.init(_required: nil)
        }
    }
    
    public static func _uninitializedInstance() -> RelatedModels<Model> {
        .init(_required: nil)
    }
}
