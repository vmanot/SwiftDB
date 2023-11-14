//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Merge
import Runtime
import Swallow
import SwiftUI

/// A property accessor for entity attributes.
@propertyWrapper
public final class _EntityAttribute<Value>: _EntityPropertyAccessor, EntityPropertyAccessor, Logging, ObservableObject, PropertyWrapper {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var objectWillChangeConduit: AnyCancellable? = nil
    
    var _runtimeMetadata = _EntityPropertyAccessorRuntimeMetadata(valueType: Value.self)
    
    public var name: String?
    
    private let traits: [EntityAttributeTrait]
    private var initialValue: InitialValue
    
    var _underlyingRecordProxy: _DatabaseRecordProxy?
    
    private var isOptional: Bool {
        Value.self is any OptionalProtocol.Type
    }
    
    public var wrappedValue: Value {
        get {
            _runtimeMetadata.didAccessWrappedValueGetter = true
            
            if let recordProxy = _underlyingRecordProxy {
                do {
                    return try recordProxy.decodeValue(Value.self, forKey: key)
                } catch {
                    assertionFailure(error)
                    
                    return initialValue.value()
                }
            } else {
                assert(!initialValue.isResolved)
                
                return initialValue.value()
            }
        } set {
            if objectWillChangeConduit != nil {
                objectWillChange.send()
            }
            
            do {
                if let recordProxy = _underlyingRecordProxy {
                    try recordProxy.encodeValue(newValue, forKey: key)
                } else {
                    initialValue = .assigned(newValue)
                }
            } catch {
                assertionFailure(error)
            }
        }
    }
    
    public var projectedValue: _EntityAttribute {
        self
    }
    
    private init(
        traits: [EntityAttributeTrait],
        initialValue: InitialValue
    ) {
        self.traits = traits
        self.initialValue = initialValue
    }
    
    public static subscript<EnclosingSelf: Entity>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, _EntityAttribute>
    ) -> Value {
        get {
            return instance[keyPath: storageKeyPath].wrappedValue
        } set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    func initialize(with container: _DatabaseRecordProxy) throws {
        assert(_underlyingRecordProxy == nil)
        
        self._underlyingRecordProxy = container
        
        _ = try encodeInitialValueIfNecessary(into: container)
    }
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    func encodeInitialValueIfNecessary(
        into proxy: _DatabaseRecordProxy
    ) throws {
        guard try !proxy.containsValue(forKey: key), !initialValue.isResolved else {
            return
        }
        
        let value = initialValue.resolve()
        
        try proxy.encodeInitialValue(value, forKey: key)
    }
    
    public func schema() throws -> _Schema.Entity.Property {
        return _Schema.Entity.Attribute(
            name: name!.stringValue,
            propertyConfiguration: .init(isOptional: isOptional),
            attributeConfiguration: .init(
                type: .init(from: Value.self),
                attributeType: _Schema.Entity.AttributeType(from: Value.self),
                traits: traits,
                defaultValue: initialValue._nonLazyValue.flatMap({ (value: Value) -> AnyCodableOrNSCodingValue? in
                    do {
                        return try AnyCodableOrNSCodingValue(from: value)
                    } catch {
                        assertionFailure(error)
                        
                        return nil
                    }
                })
            )
        )
    }
    
    // MARK: - Initializers
    
    public convenience init(
        wrappedValue: @autoclosure @escaping () -> Value,
        traits: [EntityAttributeTrait] = []
    ) {
        self.init(
            traits: traits,
            initialValue: .lazy(wrappedValue)
        )
    }
    
    public convenience init(
        wrappedValue: @autoclosure @escaping () -> Value,
        _ traits: EntityAttributeTrait...
    ) {
        self.init(
            traits: traits,
            initialValue: .lazy(wrappedValue)
        )
    }
    
    @_disfavoredOverload
    public convenience init(defaultValue: Value, traits: [EntityAttributeTrait] = []) {
        self.init(
            traits: traits,
            initialValue: .default(defaultValue)
        )
    }
    
    @_disfavoredOverload
    public convenience init(defaultValue: Value, _ traits: EntityAttributeTrait...) {
        self.init(
            traits: traits,
            initialValue: .default(defaultValue)
        )
    }
}

// MARK: - Auxiliary

extension _EntityAttribute {
    enum AccessError: _SwiftDB_Error {
        case failedToResolveInitialValue
    }
    
    fileprivate enum InitialValue {
        case lazy(() -> Value)
        case `default`(Value)
        case assigned(Value)
        
        case resolved(Value)
        
        var isResolved: Bool {
            if case .resolved = self {
                return true
            } else {
                return false
            }
        }
        
        var _nonLazyValue: Value? {
            switch self {
                case .lazy:
                    return nil
                case .default(let value):
                    return value
                case .assigned(let value):
                    return value
                case .resolved(let value):
                    return value
            }
        }
        
        func value() -> Value {
            switch self {
                case .lazy(let makeValue):
                    return makeValue()
                case .default(let value):
                    return value
                case .assigned(let value):
                    return value
                case .resolved(let value):
                    return value
            }
        }
        
        mutating func resolve() -> Value {
            guard !isResolved else {
                return value()
            }
            
            let value = self.value()
            
            self = .resolved(value)
            
            return value
        }
    }
}

extension _EntityAttribute: @unchecked Sendable where Value: Sendable {
    
}
