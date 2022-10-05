//
// Copyright (c) Vatsal Manot
//

import Foundation
import Runtime
import Swallow

public struct _opaque_EntityPropertyAccessorRuntimeMetadata {
    let valueType: Any.Type
    
    var wrappedValueAccessToken: AnyHashable?
    var wrappedValue_didSet_token: AnyHashable?
}

// MARK: - Extensions -

public protocol EntityPropertyAccessor: _opaque_ObservableObject, ObservableObject, PropertyWrapper {
    var _runtimeMetadata: _opaque_EntityPropertyAccessorRuntimeMetadata { get set }
    
    var propertyConfiguration: _Schema.Entity.PropertyConfiguration { get set }
    var _underlyingRecordContainer: _AnyDatabaseRecordContainer? { get set }
    
    var name: String? { get set }
    
    func schema() throws -> _Schema.Entity.Property
    func initialize(with _underlyingRecordContainer: _AnyDatabaseRecordContainer) throws

    var wrappedValue: WrappedValue { get }
    
    func decode(from _: Decoder) throws
    func encode(to _: Encoder) throws
}

extension EntityPropertyAccessor {
    var key: AnyStringKey {
        get throws {
            try name.map(AnyStringKey.init(stringValue:)).unwrap()
        }
    }
}
