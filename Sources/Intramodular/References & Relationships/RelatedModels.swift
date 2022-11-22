//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

/// An collection of models related to an entity.
public struct RelatedModels<Model: Entity & Identifiable>: Sequence {
    public static var entityCardinality: _Schema.Entity.Relationship.EntityCardinality {
        .many
    }
    
    let transactionContext: _SwiftDB_TaskContext?
    let relationship: AnyDatabaseRecordRelationship
    
    init(
        transactionContext: _SwiftDB_TaskContext,
        relationship: AnyDatabaseRecordRelationship
    ) {
        self.transactionContext = transactionContext
        self.relationship = relationship
    }
    
    public init(noRelatedModels: Void) {
        self.transactionContext = nil
        self.relationship = .init(erasing: NoDatabaseRecordRelationship<AnyDatabaseRecord>())
    }
    
    public func makeIterator() -> AnyIterator<Model> {
        do {
            return try _withSwiftDBTaskContext(transactionContext) { context in
                AnyIterator(try relationship.toManyRelationship().all().map({ try Model(from: context._recordProxy(for: $0)) }).makeIterator())
            }
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
        from container: _DatabaseRecordProxy,
        forKey key: CodingKey
    ) throws -> Self {
        try _withSwiftDBTaskContext { context in
            self.init(
                transactionContext: context,
                relationship: try container.relationship(for: key)
            )
        }
    }
    
    public func encode(to record: _DatabaseRecordProxy, forKey key: CodingKey) throws {
        fatalError()
    }
}

extension RelatedModels {
    public func insert(_ model: Model) {
        do {
            try relationship.toManyRelationship().insert(model._databaseRecordProxy.unwrap().record)
        } catch {
            assertionFailure()
        }
    }
    
    public func remove(_ model: Model) {
        do {
            try relationship.toManyRelationship().remove(model._databaseRecordProxy.unwrap().record)
        } catch {
            assertionFailure()
        }
    }
    
    @discardableResult
    public func remove(at offsets: IndexSet) -> AnySequence<Model> {
        let models = self.models(at: offsets)
        
        for model in models {
            do {
                try relationship.toManyRelationship().remove(AnyDatabaseRecord(from: model))
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
