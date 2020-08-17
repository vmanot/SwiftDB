//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow
import SwiftUIX

public struct RelatedModels<E: Entity>: EntityRelatable, Sequence {
    public typealias RelatableEntityType = E
    
    public static var entityCardinality: EntityCardinality {
        .many
    }
    
    var base: Set<NSManagedObject>
    
    public init(base: Set<NSManagedObject>) {
        self.base = base
    }
    
    public init() {
        self.base = .init()
    }
    
    public func makeIterator() -> AnyIterator<E> {
        .init(base.lazy.map({ E.init(base: $0)! }).makeIterator())
    }
}

extension RelatedModels {
    public static func decode(from base: NSManagedObject, forKey key: AnyStringKey) throws -> Self {
        guard let value = base.value(forKey: key.stringValue) else {
            return .init()
        }
        
        return .init(base: try cast(try cast(value, to: NSSet.self), to: Set<NSManagedObject>.self))
    }
    
    public func encode(to base: NSManagedObject, forKey key: AnyStringKey) throws  {
        base.setValue(self.base as NSSet, forKey: key.stringValue)
    }
}

extension RelatedModels {
    public mutating func insert(_ model: E) {
        base.insert(model.base!)
    }
    
    public mutating func remove(_ model: E) {
        base.remove(model.base!)
    }
    
    public mutating func set<S: Sequence>(_ models: S) where S.Element == E {
        base = Set(models.lazy.map({ $0.base! }))
    }
}
