//
// Copyright (c) Vatsal Manot
//

import CoreData
import SwiftUIX

public struct RelatedModels<E: Entity>: EntityRelatable, Sequence {
    public typealias RelatableEntityType = E
    
    public static var entityCardinality: EntityCardinality {
        .many
    }
    
    var base: Set<NSManagedObject>
    
    public func makeIterator() -> AnyIterator<E> {
        .init(base.lazy.map({ E.init(base: $0)! }).makeIterator())
    }
}

extension RelatedModels {
    public mutating func insert(_ model: E) {
        base.insert(model.base!)
    }
    
    public mutating func remove(_ model: E) {
        base.remove(model.base!)
    }
}
