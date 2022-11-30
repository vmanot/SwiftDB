//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Merge
import Runtime
import Swallow
import SwiftUI

/// A property accessor for entity attributes.
@propertyWrapper
public final class Attribute<Value>: EntityPropertyAccessor, Loggable, ObservableObject, PropertyWrapper {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var objectWillChangeConduit: AnyCancellable? = nil
    
    public var _runtimeMetadata = EntityPropertyAccessorRuntimeMetadata(valueType: Value.self)
    public var name: String?
    
    private let traits: [EntityAttributeTrait]
    private var initialValue: InitialValue
    
    public var _underlyingRecordProxy: _DatabaseRecordProxy?
    
    private var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            _runtimeMetadata.wrappedValueAccessToken = UUID()
            
            if let recordProxy = _underlyingRecordProxy {
                do {
                    return try recordProxy.decode(Value.self, forKey: key)
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
                    try recordProxy.encode(newValue, forKey: key)
                } else {
                    initialValue = .assigned(newValue)
                }
            } catch {
                assertionFailure(error)
            }
        }
    }
    
    public var projectedValue: Binding<Value> {
        .init(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
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
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Attribute>
    ) -> Value {
        get {
            let _self = instance[keyPath: storageKeyPath]
            
            if _self.objectWillChangeConduit == nil {
                _self.objectWillChangeConduit = _self.objectWillChange
                    .publish(to: instance)
                    .sink()
            }
            
            return instance[keyPath: storageKeyPath].wrappedValue
        } set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    public func initialize(with container: _DatabaseRecordProxy) throws {
        assert(_underlyingRecordProxy == nil)
        
        self._underlyingRecordProxy = container
        
        _ = try encodeInitialValueIfNecessary(into: container)
    }
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    func encodeInitialValueIfNecessary(
        into _underlyingRecordProxy: _DatabaseRecordProxy
    ) throws {
        guard try !_underlyingRecordProxy.containsValue(forKey: key), !initialValue.isResolved else {
            return
        }
        
        let value = initialValue.resolve()
        
        try _underlyingRecordProxy.encode(value, forKey: key)
    }
    
    public func schema() throws -> _Schema.Entity.Property {
        let valueType = (Value.self as? _opaque_Optional.Type)?._opaque_Optional_Wrapped ?? Value.self
        
        return _Schema.Entity.Attribute(
            name: name!.stringValue,
            propertyConfiguration: .init(isOptional: isOptional),
            attributeConfiguration: .init(
                type: _Schema.Entity.AttributeType(from: valueType),
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
    
    // MARK: - Initializers -
    
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

// MARK: - Auxiliary -

extension Attribute {
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

