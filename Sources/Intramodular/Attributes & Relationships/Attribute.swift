//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Runtime
import Swallow
import SwiftUI

/// A property accessor for entity attributes.
@propertyWrapper
public final class Attribute<Value>: _opaque_EntityPropertyAccessor, EntityPropertyAccessor, ObservableObject, PropertyWrapper {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var objectWillChangeConduit: AnyCancellable? = nil
    
    var name: String?
    var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration
    var typeDescriptionHint: DatabaseSchema.Entity.AttributeType?
    
    var initialValue: Value?
    let decodeImpl: (Attribute) throws -> Value
    let encodeImpl: (Attribute, Value) throws -> Void
    
    var underlyingRecord: _opaque_DatabaseRecord?
    
    public var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var wrappedValue: Value {
        get {
            do {
                return try decodeImpl(self)
            } catch {
                assertionFailure(String(describing: error))
                
                if let initialValue = initialValue {
                    return initialValue
                } else if let type = Value.self as? Initiable.Type {
                    return type.init() as! Value
                } else {
                    try! error.throw()
                }
            }
        } set {
            if objectWillChangeConduit != nil {
                objectWillChange.send()
            }
            
            if let underlyingRecord = underlyingRecord {
                guard underlyingRecord.isInitialized else {
                    return
                }
                
                try! encodeImpl(self, newValue)
            } else {
                initialValue = newValue
            }
        }
    }
    
    public var projectedValue: Binding<Value> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public var _runtime_wrappedValueType: Any.Type {
        (Value.self as? _opaque_Optional.Type)?._opaque_Optional_Wrapped ?? Value.self
    }
    
    init(
        initialValue: Value?,
        decodeImpl: @escaping (Attribute) throws -> Value,
        encodeImpl: @escaping (Attribute, Value) throws -> Void,
        propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration
    ) {
        self.initialValue = initialValue
        self.decodeImpl = decodeImpl
        self.encodeImpl = encodeImpl
        self.propertyConfiguration = propertyConfiguration
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
        DatabaseSchema.Entity.Attribute(
            name: name!.stringValue,
            propertyConfiguration: propertyConfiguration,
            attributeConfiguration: .init(
                type: determineSchemaAttributeType(),
                defaultValue: initialValue.flatMap({ (value: Value) -> AnyCodableOrNSCodingValue? in
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
    
    func _runtime_initializePostNameResolution() throws {
        self.propertyConfiguration.isOptional = isOptional
        
        try _runtime_encodeDefaultValueIfNecessary()
    }
    
    /// Encode the `defaultValue` if necessary.
    /// Needed for required attributes, otherwise the underlying object crashes on save.
    func _runtime_encodeDefaultValueIfNecessary() throws {
        guard let underlyingRecord = underlyingRecord else {
            return
        }
        
        let name = try self.name.unwrap()
        
        if isOptional && !underlyingRecord.containsValue(forKey: AnyStringKey(stringValue: name)) {
            _ = self.wrappedValue // force an evaluation
        }
    }
    
    private func determineSchemaAttributeType() -> DatabaseSchema.Entity.AttributeType {
        TODO.whole(.refactor, note: "Make less dependent on CoreData")

        if let type = _runtime_wrappedValueType as? NSPrimitiveAttributeCoder.Type, let result = DatabaseSchema.Entity.AttributeType(type.toNSAttributeType()) {
            return result
        } else if let wrappedValue = initialValue as? NSAttributeCoder, let result = DatabaseSchema.Entity.AttributeType(wrappedValue.getNSAttributeType()) {
            return result
        } else if let typeDescriptionHint = typeDescriptionHint {
            return typeDescriptionHint
        } else if let type = _runtime_wrappedValueType as? NSSecureCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else if let type = _runtime_wrappedValueType as? NSCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else if let initialValue = initialValue, let type = (try? AnyCodableOrNSCodingValue(from: initialValue).cocoaObjectValue()).map({ type(of: $0) }) {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else {
            return .transformable(class: NSDictionary.self, transformerName: "NSSecureUnarchiveFromData")
        }
    }

    // MARK: - Initializers -

    public convenience init(
        wrappedValue: Value
    ) {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { attribute in
                try attribute
                    .underlyingRecord
                    .unwrap()
                    .decode(Value.self, forKey: attribute.key.unwrap())
            },
            encodeImpl: { attribute, newValue in
                try attribute
                    .underlyingRecord
                    .unwrap()
                    .encode(newValue, forKey: attribute.key.unwrap())
            },
            propertyConfiguration: .init()
        )
    }

    public convenience init(
        wrappedValue: Value
    ) where Value: NSAttributeCoder {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { attribute in
                try attribute
                    .underlyingRecord
                    .unwrap()
                    .decode(Value.self, forKey: attribute.key.unwrap())
            },
            encodeImpl: { attribute, newValue in
                try attribute
                    .underlyingRecord
                    .unwrap()
                    .encode(newValue, forKey: attribute.key.unwrap())
            },
            propertyConfiguration: .init()
        )
    }
}
