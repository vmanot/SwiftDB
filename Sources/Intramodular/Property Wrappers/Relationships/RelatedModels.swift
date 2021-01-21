//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

/// An collection of models related to an entity.
public struct RelatedModels<Model: Entity & Identifiable>: Sequence {
    @inlinable
    public static var entityCardinality: EntityCardinality {
        .many
    }
    
    @usableFromInline
    var base: Set<NSManagedObject>
    
    public init(base: Set<NSManagedObject>) {
        self.base = base
    }
    
    public init(noRelatedModels: Void) {
        self.base = .init()
    }
    
    public func makeIterator() -> AnyIterator<Model> {
        .init(base.lazy.map({ Model(_runtime_underlyingRecord: _CoreData.DatabaseRecord(base: $0)) }).makeIterator())
    }
}

extension RelatedModels: EntityRelatable {
    public typealias RelatableEntityType = Model
    
    @inlinable
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        let key = key.stringValue
        
        guard let value = base.value(forKey: key) else {
            base.setValue(NSSet(), forKey: key)
            
            return .init(noRelatedModels: ())
        }
        
        return .init(base: try cast(try cast(value, to: NSSet.self), to: Set<NSManagedObject>.self))
    }
    
    @inlinable
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self.base as NSSet, forKey: key.stringValue)
    }
    
    public func exportRelatableModels() -> [Model] {
        .init(self)
    }
}

extension RelatedModels {
    public mutating func insert(_ model: Model) {
        base.insert((model._runtime_underlyingRecord as! _CoreData.DatabaseRecord).base)
    }
    
    public mutating func remove(_ model: Model) {
        base.remove((model._runtime_underlyingRecord as! _CoreData.DatabaseRecord).base)
    }
    
    public mutating func set<S: Sequence>(_ models: S) where S.Element == Model {
        base = Set(models.lazy.map({ $0._runtime_underlyingRecord as! _CoreData.DatabaseRecord }).map({ $0.base }))
    }
}
