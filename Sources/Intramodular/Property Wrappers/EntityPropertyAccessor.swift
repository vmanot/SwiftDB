//
// Copyright (c) Vatsal Manot
//

import Foundation
import Runtime
import Swallow

public struct EntityPropertyAccessorRuntimeMetadata {
    let valueType: Any.Type
    
    var wrappedValueAccessToken: AnyHashable?
    var wrappedValue_didSet_token: AnyHashable?
}

// MARK: - Extensions -

public protocol EntityPropertyAccessor: _opaque_ObservableObject, ObservableObject, PropertyWrapper {
    var _runtimeMetadata: EntityPropertyAccessorRuntimeMetadata { get set }
    
    var _underlyingRecordProxy: _DatabaseRecordProxy? { get set }
    
    var name: String? { get set }
    
    func schema() throws -> _Schema.Entity.Property
    func initialize(with _underlyingRecordProxy: _DatabaseRecordProxy) throws
    
    var wrappedValue: WrappedValue { get }
}

// MARK: - Extensions -

extension EntityPropertyAccessor {
    var key: AnyCodingKey {
        get throws {
            try name.map(AnyCodingKey.init(stringValue:)).unwrap()
        }
    }
}
