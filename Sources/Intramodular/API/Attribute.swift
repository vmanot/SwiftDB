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
public final class Attribute<Value>: _opaque_PropertyAccessor, ObservableObject, PropertyWrapper {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var objectWillChangeConduit: AnyCancellable? = nil
    
    var name: String?
    var propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration
    var attributeConfiguration: DatabaseSchema.Entity.AttributeConfiguration
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
                assertionFailure(error.localizedDescription)
                
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
        propertyConfiguration: DatabaseSchema.Entity.PropertyConfiguration,
        attributeConfiguration: DatabaseSchema.Entity.AttributeConfiguration
    ) {
        self.initialValue = initialValue
        self.decodeImpl = decodeImpl
        self.encodeImpl = encodeImpl
        self.propertyConfiguration = propertyConfiguration
        self.attributeConfiguration = attributeConfiguration
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
            attributeConfiguration: attributeConfiguration
        )
    }
    
    public func _runtime_initializePostNameResolution() throws {
        self.propertyConfiguration.isOptional = isOptional
        self.attributeConfiguration.type = determineSchemaAttributeType()

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
        } else {
            return .transformable(class: NSDictionary.self, transformerName: "NSSecureUnarchiveFromData")
        }
    }
}

// MARK: - Initializers -

extension Attribute where Value: NSAttributeCoder {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil
    ) {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { attribute in
                try attribute.underlyingRecord.unwrap().decode(Value.self, forKey: attribute.key.unwrap(), initialValue: wrappedValue)
            },
            encodeImpl: { attribute, newValue in
                try attribute.underlyingRecord.unwrap().encode(newValue, forKey: attribute.key.unwrap())
            },
            propertyConfiguration: .init(),
            attributeConfiguration: .init(
                type: .undefined,
                allowsExternalBinaryDataStorage: false,
                preservesValueInHistoryOnDeletion: false
            )
        )
    }
}

extension Attribute  {
    public convenience init(
        wrappedValue: Value
    ) {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { attribute in
                try attribute.underlyingRecord.unwrap().decode(
                    Value.self,
                    forKey: attribute.key.unwrap(),
                    initialValue: attribute.initialValue
                )
            },
            encodeImpl: { attribute, newValue in
                try attribute.underlyingRecord.unwrap().encode(
                    newValue,
                    forKey: attribute.key.unwrap()
                )
            },
            propertyConfiguration: .init(),
            attributeConfiguration: .init(
                type: .undefined,
                allowsExternalBinaryDataStorage: false,
                preservesValueInHistoryOnDeletion: false
            )
        )
    }
}

/*extension Attribute where Value: RawRepresentable, Value.RawValue: Codable & NSPrimitiveAttributeCoder {
 public convenience init(
 wrappedValue: Value,
 name: String? = nil
 ) {
 self.init(
 initialValue: wrappedValue,
 decodeImpl: { attribute in
 try Value(
 rawValue: try attribute.underlyingRecord.unwrap().decode(
 Value.RawValue.self,
 forKey: attribute.key.unwrap(),
 initialValue: attribute.initialValue?.rawValue
 )
 ).unwrap()
 },
 encodeImpl: { attribute, newValue in
 try attribute.underlyingRecord.unwrap().encode(
 newValue.rawValue,
 forKey: attribute.key.unwrap()
 )
 },
 name: name,
 )
 }
 
 public convenience init(
 wrappedValue: Value,
 name: String? = nil,
 isTransient: Bool = false,
 allowsExternalBinaryDataStorage: Bool = false,
 preservesValueInHistoryOnDeletion: Bool = false
 ) where Value: Codable {
 self.init(
 initialValue: wrappedValue,
 decodeImpl: { attribute in
 try Value(
 rawValue: try attribute.underlyingRecord.unwrap().decode(
 Value.RawValue.self,
 forKey: attribute.key.unwrap(),
 initialValue: attribute.initialValue?.rawValue
 )
 ).unwrap()
 },
 encodeImpl: { attribute, newValue in
 try attribute.underlyingRecord.unwrap().encode(
 newValue.rawValue,
 forKey: attribute.key.unwrap()
 )
 },
 name: name,
 propertyConfiguration: .init(isOptional: self.isOptional),
 attributeConfiguration: .init(
 type: .undefined,
 defaultValue: nil,
 allowsExternalBinaryDataStorage: false,
 preservesValueInHistoryOnDeletion: false
 )
 )
 }
 }*/
