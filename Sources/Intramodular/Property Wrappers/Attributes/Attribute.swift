//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow
import SwiftUI

/// A property accessor for entity attributes.
@propertyWrapper
public final class Attribute<Value>: _opaque_PropertyAccessor, ObservableObject, PropertyWrapper {
    @usableFromInline
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    @usableFromInline
    var underlyingRecord: DatabaseRecord?
    @usableFromInline
    var initialValue: Value?
    
    @usableFromInline
    let decodeImpl: (Attribute) throws -> Value
    @usableFromInline
    let encodeImpl: (Attribute, Value) throws -> Void
    
    public lazy var objectWillChange = ObservableObjectPublisher()
    
    private var objectWillChangeConduit: AnyCancellable? = nil
    
    public var name: String?
    public var isTransient: Bool = false
    public var renamingIdentifier: String?
    public var typeDescriptionHint: EntityAttributeTypeDescription?
    public var allowsExternalBinaryDataStorage: Bool = false
    public var preservesValueInHistoryOnDeletion: Bool = false
    
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
    
    public var typeDescription: EntityAttributeTypeDescription {
        if let type = _runtime_wrappedValueType as? NSPrimitiveAttributeCoder.Type, let result = EntityAttributeTypeDescription(type.toNSAttributeType()) {
            return result
        } else if let wrappedValue = initialValue as? NSAttributeCoder, let result = EntityAttributeTypeDescription(wrappedValue.getNSAttributeType()) {
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
    
    init(
        initialValue: Value?,
        decodeImpl: @escaping (Attribute) throws -> Value,
        encodeImpl: @escaping (Attribute, Value) throws -> Void,
        name: String?,
        isTransient: Bool,
        typeDescriptionHint: EntityAttributeTypeDescription?,
        allowsExternalBinaryDataStorage: Bool,
        preservesValueInHistoryOnDeletion: Bool
    ) {
        self.initialValue = initialValue
        self.decodeImpl = decodeImpl
        self.encodeImpl = encodeImpl
        self.isTransient = isTransient
        self.typeDescriptionHint = typeDescriptionHint
        self.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        self.preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
    }
    
    public static subscript<EnclosingSelf: Entity>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Attribute>
    ) -> Value {
        get {
            let _self = instance[keyPath: storageKeyPath]
            
            if let objectWillChange = instance._opaque_objectWillChange, _self.objectWillChangeConduit == nil {
                _self.objectWillChangeConduit = _self.objectWillChange
                    .publish(to: objectWillChange)
            }
            
            return instance[keyPath: storageKeyPath].wrappedValue
        } set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

extension Attribute where Value: NSAttributeCoder {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { attribute in
                try attribute.underlyingRecord.unwrap().decode(Value.self, forKey: attribute.key.unwrap())
            },
            encodeImpl: { attribute, newValue in
                try attribute.underlyingRecord.unwrap().encode(newValue, forKey: attribute.key.unwrap())
            },
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: nil,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: Codable {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
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
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: nil,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: Codable & NSAttributeCoder {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
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
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: nil,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: Codable & NSPrimitiveAttributeCoder {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
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
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: nil,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: RawRepresentable, Value.RawValue: Codable & NSPrimitiveAttributeCoder {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
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
            isTransient: isTransient,
            typeDescriptionHint: nil,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
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
            isTransient: isTransient,
            typeDescriptionHint: nil,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

// MARK: - Auxiliary Implementation -

extension Attribute {
    public func toEntityPropertyDescription() -> EntityPropertyDescription {
        EntityAttributeDescription(
            name: name!.stringValue,
            isOptional: isOptional,
            isTransient: isTransient,
            renamingIdentifier: renamingIdentifier,
            type: typeDescription,
            defaultValue: initialValue as? NSPrimitiveAttributeCoder,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension NSAttributeDescription {
    convenience init(_ attribute: _opaque_PropertyAccessor) {
        self.init(attribute.toEntityPropertyDescription() as! EntityAttributeDescription)
    }
}
