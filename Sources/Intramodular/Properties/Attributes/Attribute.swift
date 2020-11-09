//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow
import SwiftUI

/// A shadow protocol for `Attribute`.
protocol _opaque_Attribute: _opaque_PropertyAccessor {
    var _opaque_initialValue: Any? { get }
    
    var typeDescription: EntityAttributeTypeDescription { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
}

/// A property accessor for entity attributes.
@propertyWrapper
public final class Attribute<Value>: _opaque_Attribute, ObservableObject, PropertyWrapper {
    @usableFromInline
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    @usableFromInline
    var underlyingObject: NSManagedObject?
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
    
    @usableFromInline
    var hasNonNilInitialValue: Bool {
        if let initialValue = initialValue {
            return (initialValue as? _opaque_Optional)?.isNotNil ?? true
        } else {
            return false
        }
    }
    
    public var _opaque_initialValue: Any? {
        initialValue.map({ $0 as Any })
    }
    
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
            
            if let underlyingObject = underlyingObject {
                guard underlyingObject.managedObjectContext != nil else {
                    return
                }
                
                try! encodeImpl(self, newValue)
            } else {
                initialValue = newValue
            }
        }
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
    
    public var projectedValue: Binding<Value> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public var typeDescription: EntityAttributeTypeDescription {
        if let type = Value.self as? NSPrimitiveAttributeCoder.Type, let result = EntityAttributeTypeDescription(type.toNSAttributeType()) {
            return result
        } else if let wrappedValue = initialValue as? NSAttributeCoder, let result = EntityAttributeTypeDescription(wrappedValue.getNSAttributeType()) {
            return result
        } else if let typeDescriptionHint = typeDescriptionHint {
            return typeDescriptionHint
        } else if let type = Value.self as? NSSecureCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else if let type = Value.self as? NSCoding.Type {
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
                if attribute.hasNonNilInitialValue {
                    return try Value.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap(),
                        defaultValue: wrappedValue
                    )
                } else {
                    return try Value.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap()
                    )
                }
            },
            encodeImpl: { attribute, newValue in
                try newValue.encode(
                    to: attribute.underlyingObject.unwrap(),
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

extension Attribute where Value: Codable {
    public convenience init(
        wrappedValue: Value,
        name: String? = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        let hasNonNilInitialValue = (wrappedValue as? _opaque_Optional)?.isNotNil ?? true
        
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { attribute in
                if hasNonNilInitialValue {
                    return try _CodableToNSAttributeCoder<Value>.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap(),
                        defaultValue: .init(wrappedValue)
                    )
                    .value
                } else {
                    return try _CodableToNSAttributeCoder<Value>.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap()
                    )
                    .value
                }
            },
            encodeImpl: { attribute, newValue in
                try _CodableToNSAttributeCoder(newValue).encode(
                    to: attribute.underlyingObject.unwrap(),
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
                if attribute.hasNonNilInitialValue {
                    return try Value.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap(),
                        defaultValue: wrappedValue
                    )
                } else {
                    return try Value.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap()
                    )
                }
            },
            encodeImpl: { attribute, newValue in
                try newValue.encode(
                    to: attribute.underlyingObject.unwrap(),
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
                if attribute.hasNonNilInitialValue {
                    return try Value.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap(),
                        defaultValue: wrappedValue
                    )
                } else {
                    return try Value.decode(
                        from: attribute.underlyingObject.unwrap(),
                        forKey: attribute.key.unwrap()
                    )
                }
            },
            encodeImpl: { attribute, newValue in
                try newValue.encode(
                    to: attribute.underlyingObject.unwrap(),
                    forKey: attribute.key.unwrap()
                )
            },
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: EntityAttributeTypeDescription(Value.toNSAttributeType()),
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
                if attribute.hasNonNilInitialValue {
                    return try Value(
                        rawValue: try Value.RawValue.decode(
                            from: attribute.underlyingObject.unwrap(),
                            forKey: attribute.key.unwrap(),
                            defaultValue: wrappedValue.rawValue
                        )
                    )
                    .unwrap()
                } else {
                    return try Value(
                        rawValue: try Value.RawValue.decode(
                            from: attribute.underlyingObject.unwrap(),
                            forKey: attribute.key.unwrap()
                        )
                    )
                    .unwrap()
                }
            },
            encodeImpl: { attribute, newValue in
                try newValue.rawValue.encode(
                    to: attribute.underlyingObject.unwrap(),
                    forKey: attribute.key.unwrap()
                )
            },
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: EntityAttributeTypeDescription(Value.toNSAttributeType()),
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
                if attribute.hasNonNilInitialValue {
                    return try Value(
                        rawValue: try Value.RawValue.decode(
                            from: attribute.underlyingObject.unwrap(),
                            forKey: attribute.key.unwrap(),
                            defaultValue: wrappedValue.rawValue
                        )
                    )
                    .unwrap()
                } else {
                    return try Value(
                        rawValue: try Value.RawValue.decode(
                            from: attribute.underlyingObject.unwrap(),
                            forKey: attribute.key.unwrap()
                        )
                    )
                    .unwrap()
                }
            },
            encodeImpl: { attribute, newValue in
                try newValue.rawValue.encode(
                    to: attribute.underlyingObject.unwrap(),
                    forKey: attribute.key.unwrap()
                )
            },
            name: name,
            isTransient: isTransient,
            typeDescriptionHint: EntityAttributeTypeDescription(Value.toNSAttributeType()),
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
    convenience init(_ attribute: _opaque_Attribute) {
        self.init(attribute.toEntityPropertyDescription() as! EntityAttributeDescription)
    }
}
