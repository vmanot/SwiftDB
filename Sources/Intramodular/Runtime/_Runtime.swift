//
// Copyright (c) Vatsal Manot
//

import Swallow

@usableFromInline
final class _Runtime: Hashable {
    @usableFromInline
    static let `default` = _Runtime()
    
    @usableFromInline
    struct TypeCache: Hashable {
        @usableFromInline
        var entity: [String: Metatype<_opaque_Entity.Type>] = [:]
    }
    
    @usableFromInline
    var typeCache = TypeCache()
    
    @usableFromInline
    func hash(into hasher: inout Hasher) {
        hasher.combine(typeCache)
    }
}

// MARK: - Helpers -

extension CodingUserInfoKey {
    public static let _SwiftDB_runtime = CodingUserInfoKey(rawValue: "_SwiftDB_runtime")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_runtime: _Runtime {
        self[._SwiftDB_runtime] as? _Runtime ?? .default
    }
}
