//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

public struct RelatedModels<Model: Entity>: Sequence {
    @inlinable
    public static var entityCardinality: EntityCardinality {
        .many
    }
    
    @usableFromInline
    var base: Set<NSManagedObject>
    
    @inlinable
    public init(base: Set<NSManagedObject>) {
        self.base = base
    }
    
    @inlinable
    public init() {
        self.base = .init()
    }
    
    @inlinable
    public func makeIterator() -> AnyIterator<Model> {
        .init(base.lazy.map({ Model(_runtime_underlyingObject: $0)! }).makeIterator())
    }
}

extension RelatedModels: EntityRelatable {
    public typealias RelatableEntityType = Model
    
    @inlinable
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        guard let value = base.value(forKey: key.stringValue) else {
            return .init()
        }
        
        return .init(base: try cast(try cast(value, to: NSSet.self), to: Set<NSManagedObject>.self))
    }
    
    @inlinable
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self.base as NSSet, forKey: key.stringValue)
    }
}

extension RelatedModels {
    @inlinable
    public mutating func insert(_ model: Model) {
        base.insert(model._runtime_underlyingObject!)
    }
    
    @inlinable
    public mutating func remove(_ model: Model) {
        base.remove(model._runtime_underlyingObject!)
    }
    
    @inlinable
    public mutating func set<S: Sequence>(_ models: S) where S.Element == Model {
        base = Set(models.lazy.map({ $0._runtime_underlyingObject! }))
    }
}
