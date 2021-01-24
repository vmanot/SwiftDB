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

// MARK: - Auxiliary Implementation -

extension CodingUserInfoKey {
    public static let _SwiftDB_databaseRuntime = CodingUserInfoKey(rawValue: "_SwiftDB_runtime")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_databaseRuntime: DatabaseRuntime? {
        self[._SwiftDB_databaseRuntime].flatMap({ $0 as? DatabaseRuntime })
    }
}
