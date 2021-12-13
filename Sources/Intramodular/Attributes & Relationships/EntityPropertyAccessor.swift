//
// Copyright (c) Vatsal Manot
//

import Foundation
import Runtime
import Swallow

/// A prototype for `NSPropertyDescription`.
protocol _opaque_EntityPropertyAccessor: AnyObject, _opaque_ObservableObject, _opaque_PropertyWrapper {
    var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration { get set }
    var underlyingRecord: _opaque_DatabaseRecord? { get set }
    
    var name: String? { get set }
        
    func schema() throws -> DatabaseSchema.Entity.Property
    func _runtime_initializePostNameResolution() throws
    
    // MARK: - Decoding & Encoding
    
    func decode(from _: Decoder) throws
    func encode(to _: Encoder) throws
}

// MARK: - Extensions -

extension _opaque_EntityPropertyAccessor {
    @usableFromInline
    var key: AnyStringKey? {
        name.map(AnyStringKey.init(stringValue:))
    }
}

public protocol EntityPropertyAccessor: _opaque_ObservableObject, ObservableObject, PropertyWrapper {
    var wrappedValue: WrappedValue { get }
    
    func decode(from _: Decoder) throws
    func encode(to _: Encoder) throws
}
