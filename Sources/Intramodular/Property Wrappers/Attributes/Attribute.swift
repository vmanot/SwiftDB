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
    enum AccessError: Error {
        case failedToResolveInitialValue
    }
    
    public let objectWillChange = ObservableObjectPublisher()
    
    private var objectWillChangeConduit: AnyCancellable? = nil
    
    public var _runtimeMetadata = _opaque_EntityPropertyAccessorRuntimeMetadata(valueType: Value.self)
    public var name: String?
    public var propertyConfiguration: _Schema.Entity.PropertyConfiguration
    
    var makeInitialValue: (() -> Value?)?
    var assignedInitialValue: Value?
    
    public var _underlyingRecordContainer: _AnyDatabaseRecordContainer?
    
    public var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            _runtimeMetadata.wrappedValueAccessToken = UUID()
            
            guard let recordContainer = _underlyingRecordContainer else {
                if let value = assignedInitialValue {
                    return value
                } else if let makeInitialValue = makeInitialValue {
                    let value = makeInitialValue()
                    
                    assignedInitialValue = value
                    
                    return value!
                } else {
                    fatalError(AccessError.failedToResolveInitialValue)
                }
            }
            
            do {
                if try recordContainer.containsValue(forKey: key) || isOptional {
                    let result = try recordContainer.decode(Value.self, forKey: key)
                                        
                    return result
                } else {
                    return try encodeDefaultValueIfNecessary(into: recordContainer).unwrap()
                }
            } catch {
                logger.error(error)
                
                if let initialValue = assignedInitialValue {
                    return initialValue
                } else if let type = Value.self as? Initiable.Type {
                    return type.init() as! Value
                } else {
                    fatalError(error)
                }
            }
        } set {
            if objectWillChangeConduit != nil {
                objectWillChange.send()
            }
            
            if let recordContainer = _underlyingRecordContainer {
                try! recordContainer.encode(newValue, forKey: key)
            } else {
                assignedInitialValue = newValue
            }
        }
    }
    
    public var projectedValue: Binding<Value> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    init(
        makeInitialValue: (() -> Value?)?,
        propertyConfiguration: _Schema.Entity.PropertyConfiguration
    ) {
        self.makeInitialValue = makeInitialValue
        self.propertyConfiguration = propertyConfiguration
        
        self.propertyConfiguration.isOptional = isOptional // FIXME: Move to some place better?
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
    
    public func schema() throws -> _Schema.Entity.Property {
        let valueType = (Value.self as? _opaque_Optional.Type)?._opaque_Optional_Wrapped ?? Value.self
        
        return _Schema.Entity.Attribute(
            name: name!.stringValue,
            propertyConfiguration: propertyConfiguration,
            attributeConfiguration: .init(
                type: _Schema.Entity.AttributeType(from: valueType),
                defaultValue: assignedInitialValue.flatMap({ (value: Value) -> AnyCodableOrNSCodingValue? in
                    do {
                        return try AnyCodableOrNSCodingValue(from: value)
                    } catch {
                        assertionFailure(String(describing: error))
                        
                        return nil
                    }
                }),
                allowsExternalBinaryDataStorage: false,
                preservesValueInHistoryOnDeletion: false
            )
        )
    }
    
    public func initialize(with container: _AnyDatabaseRecordContainer) throws {
        self._underlyingRecordContainer = container
        
        _ = try encodeDefaultValueIfNecessary(into: container)
    }
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    func encodeDefaultValueIfNecessary(
        into _underlyingRecordContainer: _AnyDatabaseRecordContainer
    ) throws -> Value? {
        if let assignedInitialValue = assignedInitialValue {
            let initialValue = assignedInitialValue
            
            try _underlyingRecordContainer.setInitialValue(initialValue, forKey: key)
            
            return initialValue
        } else if let makeInitialValue = makeInitialValue {
            let initialValue = makeInitialValue()
            
            try _underlyingRecordContainer.setInitialValue(initialValue, forKey: key)
            
            return initialValue
        }
        
        if try !isOptional && (try _underlyingRecordContainer.containsValue(forKey: key)) {
            _ = self.wrappedValue // force an evaluation
        }
        
        return nil
    }
    
    // MARK: - Initializers -
    
    public convenience init(
        wrappedValue: @autoclosure @escaping () -> Value,
        _ traits: [EntityAttributeTrait] = []
    ) {
        self.init(
            makeInitialValue: wrappedValue,
            propertyConfiguration: .init()
        )
    }
    
    @_disfavoredOverload
    public convenience init(defaultValue: Value) {
        self.init(
            makeInitialValue: nil,
            propertyConfiguration: .init()
        )
        
        assignedInitialValue = defaultValue
    }
}
