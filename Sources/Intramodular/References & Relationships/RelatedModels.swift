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
    
    let transactionContext: DatabaseTransactionContext?
    let relationship: AnyDatabaseRecordRelationship
    
    init(
        transactionContext: DatabaseTransactionContext,
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
            let transactionContext = try transactionContext.unwrap()

            return try transactionContext.scope {
                AnyIterator(try relationship.all().map({ try Model(from: transactionContext._recordContainer(for: $0)) }).makeIterator())
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
        from record: AnyDatabaseRecord,
        forKey key: CodingKey
    ) throws -> Self {
        try self.init(
            transactionContext: _SwiftDB_TaskLocalValues.transactionContext.unwrap(),
            relationship: try record.relationship(for: key)
        )
    }
    
    public func encode(to record: AnyDatabaseRecord, forKey key: CodingKey) throws {
        fatalError()
    }
    
    public func exportRelatableModels() -> [Model] {
        .init(self)
    }
}

extension RelatedModels {
    public func insert(_ model: Model) {
        do {
            try relationship.insert(model._underlyingDatabaseRecordContainer.unwrap().record)
        } catch {
            assertionFailure()
        }
    }
    
    public func remove(_ model: Model) {
        do {
            try relationship.remove(model._underlyingDatabaseRecordContainer.unwrap().record)
        } catch {
            assertionFailure()
        }
    }
    
    @discardableResult
    public func remove(at offsets: IndexSet) -> AnySequence<Model> {
        let models = self.models(at: offsets)
        
        for model in models {
            do {
                try relationship.remove(AnyDatabaseRecord(from: model))
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
