//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import Runtime
import Swallow

protocol _EntityPropertyAccessor: _opaque_ObservableObject, ObservableObject, PropertyWrapper {
    var _runtimeMetadata: _EntityPropertyAccessorRuntimeMetadata { get set }
    
    var _underlyingRecordProxy: _DatabaseRecordProxy? { get set }
    
    var name: String? { get set }
    
    func schema() throws -> _Schema.Entity.Property
    func initialize(with _underlyingRecordProxy: _DatabaseRecordProxy) throws
    
    var wrappedValue: WrappedValue { get }
}

public protocol EntityPropertyAccessor {
    var name: String? { get set }
}

// MARK: - Extensions

extension _EntityPropertyAccessor {
    var key: AnyCodingKey {
        get throws {
            try name.map(AnyCodingKey.init(stringValue:)).unwrap()
        }
    }
}

// MARK: - Auxiliary

struct _EntityPropertyAccessorRuntimeMetadata {
    let valueType: Any.Type
    
    var didAccessWrappedValueGetter: Bool = false
}
