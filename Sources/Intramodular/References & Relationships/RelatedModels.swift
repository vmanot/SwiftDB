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
    var base: AnyDatabaseRecordRelationship
    
    public init(base: AnyDatabaseRecordRelationship) {
        self.base = base
    }
    
    public init(noRelatedModels: Void) {
        self.base = .init(erasing: NoDatabaseRecordRelationship<AnyDatabaseRecord>())
    }
    
    public func makeIterator() -> AnyIterator<Model> {
        do {
            return AnyIterator(try base.all().map({ try Model(from: $0) }).makeIterator())
        } catch {
            assertionFailure()
            
            return AnyIterator<Model>(EmptyCollection<Element>.Iterator())
        }
    }
}

extension RelatedModels: CustomStringConvertible {
    public var description: String {
        Array(self).description
    }
}

extension RelatedModels: EntityRelatable {
    public typealias RelatableEntityType = Model
    
    public static func decode(
        from record: AnyDatabaseRecord,
        forKey key: AnyStringKey
    ) throws -> Self {
        self.init(base: try record.relationship(for: key))
    }
    
    public func encode(to record: AnyDatabaseRecord, forKey key: AnyStringKey) throws {
        fatalError()
    }
    
    public func exportRelatableModels() -> [Model] {
        .init(self)
    }
}

extension RelatedModels {
    public func insert(_ model: Model) {
        do {
            try base.insert(model._underlyingDatabaseRecord!)
        } catch {
            assertionFailure()
        }
    }
    
    public func remove(_ model: Model) {
        do {
            try base.remove(model._underlyingDatabaseRecord!)
        } catch {
            assertionFailure()
        }
    }
        
    @discardableResult
    public func remove(at offsets: IndexSet) -> AnySequence<Model> {
        let models = self.models(at: offsets)
        
        for model in models {
            do {
                try base.remove(AnyDatabaseRecord(from: model))
            } catch {
                assertionFailure()
            }
        }
        
        return models
    }
    
    // MARK: Internal
    
    private func models(at offsets: IndexSet) -> AnySequence<Model> {
        let models = Array(self)
        
        return AnySequence(offsets.map({ models[$0] }))
    }
}
