//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

public protocol _SwiftDB_Runtime: Sendable {
    func metatype(forEntityNamed: String) -> Metatype<any Entity.Type>?
    
    func convertEntityKeyPathToString(_ keyPath: AnyKeyPath) throws -> String
}

// MARK: - Conformances

public final class _SwiftDB_DefaultRuntime: _SwiftDB_Runtime, @unchecked Sendable {
    struct TypeCache: Hashable {
        var entity: [String: Metatype<any Entity.Type>] = [:]
    }
    
    var typeCache = TypeCache()
    var entityCacheMap: [Metatype<any Entity.Type>: EntityCache] = [:]
    
    public init(schema: _Schema?) throws {
        if let schema = schema {
            for entity in schema.entities {
                _ = try self.entityCache(for: schema.entityType(for: entity.id))
            }
        }
    }
    
    public func metatype(forEntityNamed name: String) -> Metatype<any Entity.Type>? {
        typeCache.entity[name]
    }
    
    
    public final class EntityCache {
        let entityType: _opaque_Entity.Type
        var fieldNameToKeyPathMap: [String: AnyKeyPath] = [:]
        
        lazy var prototype: _opaque_Entity = try! entityType.init(_databaseRecordProxy: nil)
        
        init(entityType: _opaque_Entity.Type) {
            self.entityType = entityType
        }
        
        public func _getFieldNameForKeyPath(_ keyPath: AnyKeyPath) throws -> String {
            enum KeyPathToFieldNameConversionError: Error {
                case valueTypeMismatch(Any.Type, Any.Type)
            }
            
            let valueType = try type(of: cast(keyPath, to: _opaque_KeyPathType.self))._opaque_ValueType
            
            func _accessKeyPath<T>(_ instance: T) throws  {
                let keyPath = try cast(keyPath, to: PartialKeyPath<T>.self)
                
                let _ = instance[keyPath: keyPath]
            }
            
            try _openExistential(prototype, do: _accessKeyPath)
            
            let field: any _EntityPropertyAccessor = try prototype._runtime_propertyAccessors
                .first(where: { $0._runtimeMetadata.didAccessWrappedValueGetter })
                .unwrap()
            
            guard field._runtimeMetadata.valueType == valueType else {
                throw KeyPathToFieldNameConversionError.valueTypeMismatch(field._runtimeMetadata.valueType, valueType)
            }
            
            return try field.name.unwrap()
        }
    }
    
    public func entityCache(for entityType: any Entity.Type) -> EntityCache {
        if let result = entityCacheMap[.init(entityType)] {
            return result
        } else {
            let result = EntityCache(entityType: entityType)
            
            entityCacheMap[.init(entityType)] = result
            typeCache.entity[String(describing: entityType)] = .init(entityType)
            
            return result
        }
    }
    
    public func convertEntityKeyPathToString(_ keyPath: AnyKeyPath) throws -> String {
        let rootType = try type(of: cast(keyPath, to: _opaque_PartialKeyPathType.self))._opaque_RootType
        let entityType = try cast(rootType, to: (any Entity.Type).self)
        
        return try entityCache(for: entityType)._getFieldNameForKeyPath(keyPath)
    }
}

// MARK: - Auxiliary

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
