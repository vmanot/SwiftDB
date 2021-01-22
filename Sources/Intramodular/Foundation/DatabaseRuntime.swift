//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public protocol DatabaseRuntime {
    func metatype(forEntityNamed: String) -> Metatype<_opaque_Entity.Type>?
}

// MARK: - Conformances -

final class _DefaultDatabaseRuntime: DatabaseRuntime {
    @usableFromInline
    struct TypeCache: Hashable {
        @usableFromInline
        var entity: [String: Metatype<_opaque_Entity.Type>] = [:]
    }
    
    @usableFromInline
    var typeCache = TypeCache()
    
    func metatype(forEntityNamed name: String) -> Metatype<_opaque_Entity.Type>? {
        typeCache.entity[name]
    }
}
