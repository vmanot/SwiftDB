//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
protocol _opaque_PropertyAccessor: _opaque_ObservableObject, _opaque_PropertyWrapper {
    var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration { get set }
    var underlyingRecord: _opaque_DatabaseRecord? { get set }
    
    var name: String? { get set }
    var key: AnyStringKey? { get }
    
    func decode(from _: Decoder) throws
    func encode(to _: Encoder) throws
    
    func schema() throws -> DatabaseSchema.Entity.Property
    
    mutating func _runtime_initializePostNameResolution() throws
}

// MARK: - Implementation -

extension _opaque_PropertyAccessor where Self: PropertyWrapper {
    @usableFromInline
    var key: AnyStringKey? {
        name.map(AnyStringKey.init(stringValue:))
    }
}
