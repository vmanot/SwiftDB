//
// Copyright (c) Vatsal Manot
//

import CoreData
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
    public var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration
    
    var makeInitialValue: (() -> Value?)?
    var assignedInitialValue: Value?
    
    public var underlyingRecord: AnyDatabaseRecord?
    
    public var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            _runtimeMetadata.wrappedValueAccessToken = UUID()
            
            guard let underlyingRecord = underlyingRecord else {
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
                logger.debug("Decoding value")
                
                let result = try underlyingRecord.decode(Value.self, forKey: key.unwrap())
                
                logger.debug("Decoded value: \(result)")
                
                return result
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
            
            if let underlyingRecord = underlyingRecord {
                logger.debug("Encoding value: \(newValue)")
                
                try! underlyingRecord.encode(newValue, forKey: key.forceUnwrap())
                
                logger.debug("Encoded value")
            } else {
                logger.debug("Underlying record has not been resolved. Storing assigned value as initial value.")
                
                assignedInitialValue = newValue
            }
        }
    }
    
    public var projectedValue: Binding<Value> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    init(
        makeInitialValue: (() -> Value?)?,
        propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration
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
    
    public func schema() throws -> DatabaseSchema.Entity.Property {
        let valueType = (Value.self as? _opaque_Optional.Type)?._opaque_Optional_Wrapped ?? Value.self
        
        return DatabaseSchema.Entity.Attribute(
            name: name!.stringValue,
            propertyConfiguration: propertyConfiguration,
            attributeConfiguration: .init(
                type: DatabaseSchema.Entity.AttributeType(from: valueType),
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
    
    public func initialize(with underlyingRecord: AnyDatabaseRecord) throws {
        try encodeDefaultValueIfNecessary(into: underlyingRecord)
    }
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    func encodeDefaultValueIfNecessary(into underlyingRecord: AnyDatabaseRecord) throws {
        guard let key = key else {
            return assertionFailure()
        }
        
        if let assignedInitialValue = assignedInitialValue {
            try underlyingRecord.setInitialValue(assignedInitialValue, forKey: key)
        } else if let makeInitialValue = makeInitialValue {
            try underlyingRecord.setInitialValue(makeInitialValue(), forKey: key)
        }
        
        if !isOptional && !underlyingRecord.containsValue(forKey: key) {
            _ = self.wrappedValue // force an evaluation
        }
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
