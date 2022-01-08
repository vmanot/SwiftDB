//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

public protocol _SwiftDB_Runtime {
    func metatype(forEntityNamed: String) -> Metatype<_opaque_Entity.Type>?
    
    func convertEntityKeyPathToString(_ keyPath: AnyKeyPath) throws -> String 
}

// MARK: - Conformances -

public final class _Default_SwiftDB_Runtime: _SwiftDB_Runtime {
    @usableFromInline
    struct TypeCache: Hashable {
        @usableFromInline
        var entity: [String: Metatype<_opaque_Entity.Type>] = [:]
    }
    
    @usableFromInline
    var typeCache = TypeCache()
    
    public init() {
        
    }
    
    public func metatype(forEntityNamed name: String) -> Metatype<_opaque_Entity.Type>? {
        typeCache.entity[name]
    }
    
    var entityCacheMap: [Metatype<_opaque_Entity.Type>: EntityCache] = [:]
    
    public final class EntityCache {
        let entityType: _opaque_Entity.Type
        var fieldNameToKeyPathMap: [String: AnyKeyPath] = [:]
        
        lazy var prototype: _opaque_Entity = try! entityType.init(_underlyingDatabaseRecord: nil)
        
        init(entityType: _opaque_Entity.Type) {
            self.entityType = entityType
        }
        
        public func _getFieldNameForKeyPath(_ keyPath: AnyKeyPath) throws -> String {
            let prototype = try entityType.init(_underlyingDatabaseRecord: nil)
            
            func _accessKeyPath<T>(_ instance: T) throws  {
                let keyPath = try cast(keyPath, to: PartialKeyPath<T>.self)
                
                let _ = instance[keyPath: keyPath]
            }
            
            try _openExistential(prototype, do: _accessKeyPath)
            
            let field = try prototype._runtime_propertyAccessors
                .first(where: { $0._runtimeMetadata.wrappedValueAccessToken != nil })
                .unwrap()
            
            return try field.name.unwrap()
        }
    }
    
    public func entityCache(for entityType: _opaque_Entity.Type) -> EntityCache {
        if let result = entityCacheMap[.init(entityType)] {
            return result
        } else {
            let result = EntityCache(entityType: entityType)
            
            entityCacheMap[.init(entityType)] = result
            
            return result
        }
    }
    
    public func convertEntityKeyPathToString(_ keyPath: AnyKeyPath) throws -> String {
        let rootType = try type(of: cast(keyPath, to: _opaque_PartialKeyPathType.self))._opaque_RootType
        let entityType = try cast(rootType, to: _opaque_Entity.Type.self)
        
        return try entityCache(for: entityType)._getFieldNameForKeyPath(keyPath)
    }
}

// MARK: - Auxiliary Implementation -

extension CodingUserInfoKey {
    fileprivate static let _SwiftDB_runtime = CodingUserInfoKey(rawValue: "_SwiftDB_runtime")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    public var _SwiftDB_runtime: _SwiftDB_Runtime? {
        get {
            self[._SwiftDB_runtime] as? _SwiftDB_Runtime
        } set {
            self[._SwiftDB_runtime] = newValue
        }
    }
}
