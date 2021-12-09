//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

/// An collection of models related to an entity.
public struct RelatedModels<Model: Entity & Identifiable>: Sequence {
    @inlinable
    public static var entityCardinality: DatabaseSchema.Entity.Relationship.EntityCardinality {
        .many
    }
    
    @usableFromInline
    var base: [_opaque_DatabaseRecord]
    
    public init(base: [_opaque_DatabaseRecord]) {
        self.base = base
    }
    
    public init(noRelatedModels: Void) {
        self.base = .init()
    }
    
    public func makeIterator() -> AnyIterator<Model> {
        AnyIterator(base.lazy.map({ try! Model(_underlyingDatabaseRecord: $0) }).makeIterator()) // FIXME
    }
}

extension RelatedModels: EntityRelatable {
    public typealias RelatableEntityType = Model
    
    @inlinable
    public static func decode(from base: _opaque_DatabaseRecord, forKey key: AnyStringKey) throws -> Self {
        fatalError()
    }
    
    @inlinable
    public func encode(to base: _opaque_DatabaseRecord, forKey key: AnyStringKey) throws {
        fatalError()
    }
    
    public func exportRelatableModels() -> [Model] {
        .init(self)
    }
}

extension RelatedModels {
    public mutating func insert(_ model: Model) {
        base.insert(try! model._underlyingDatabaseRecord.unwrap())
    }
    
    public mutating func remove(_ model: Model) {
        base.removeAll(where: {
            try! $0._opaque_id == model._underlyingDatabaseRecord.unwrap()._opaque_id
        })
    }
    
    public mutating func set<S: Sequence>(_ models: S) where S.Element == Model {
        base = models.map({ try! $0._underlyingDatabaseRecord.unwrap() })
    }
}
