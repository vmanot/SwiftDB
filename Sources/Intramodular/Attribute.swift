//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow
import SwiftUI

/// A property wrapper   that can read and write an attribute managed by CoreData.
@propertyWrapper
public final class Attribute<Value>: _opaque_Attribute, PropertyWrapper {
    @usableFromInline
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    
    @usableFromInline
    var underlyingObject: NSManagedObject?
    
    @usableFromInline
    let initialValue: Value?
    
    public var _opaque_initialValue: Any? {
        initialValue.map({ $0 as Any })
    }
    
    @usableFromInline
    let decodeImpl: (NSManagedObject, AnyStringKey) throws -> Value
    @usableFromInline
    let encodeImpl: (NSManagedObject, AnyStringKey, Value) throws -> Void
    
    public var name: String?
    
    public var isOptional: Bool {
        Value.self is _opaque_Optional.Type
    }
    
    public var isTransient: Bool = false
    public var renamingIdentifier: String?
    
    public var typeDescriptionHint: EntityAttributeTypeDescription?
    public var allowsExternalBinaryDataStorage: Bool = false
    public var preservesValueInHistoryOnDeletion: Bool = false
    
    public var wrappedValue: Value {
        get {
            do {
                guard let underlyingObject = underlyingObject else {
                    return try initialValue.unwrap()
                }
                
                return try decodeImpl(underlyingObject, .init(stringValue: name.unwrap()))
            } catch {
                assertionFailure()
                
                if let type = Value.self as? Initiable.Type {
                    return type.init() as! Value
                } else {
                    try! error.throw()
                }
            }
        } set {
            guard underlyingObject?.managedObjectContext != nil else {
                return
            }
            
            try! encodeImpl(underlyingObject.unwrap(), .init(stringValue: name.unwrap()), newValue)
        }
    }
    
    public var projectedValue: Binding<Value> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public var typeDescription: EntityAttributeTypeDescription {
        if let type = Value.self as? NSPrimitiveAttributeCoder.Type {
            if let result = EntityAttributeTypeDescription(type.toNSAttributeType()) {
                return result
            }
        } else if let wrappedValue = initialValue as? NSAttributeCoder {
            if let result = EntityAttributeTypeDescription(wrappedValue.getNSAttributeType()) {
                return result
            }
        } else if let typeDescriptionHint = typeDescriptionHint {
            return typeDescriptionHint
        } else if let type = Value.self as? NSSecureCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else if let type = Value.self as? NSCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else {
            return .transformable(class: NSDictionary.self, transformerName: "NSSecureUnarchiveFromData")
        }
        
        return .undefined
    }
    
    init(
        initialValue: Value?,
        decodeImpl: @escaping (NSManagedObject, AnyStringKey) throws -> Value,
        encodeImpl: @escaping (NSManagedObject, AnyStringKey, Value) throws -> Void,
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
        let hasInitialValue = (wrappedValue as? _opaque_Optional)?.isNotNil ?? true
        
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                if hasInitialValue {
                    return try Value.decode(from: object, forKey: key, defaultValue: wrappedValue)
                } else {
                    return try Value.decode(from: object, forKey: key)
                }
            },
            encodeImpl: { object, key, newValue in
                try newValue.encode(to: object, forKey: key)
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
        let hasInitialValue = (wrappedValue as? _opaque_Optional)?.isNotNil ?? true
        
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                if hasInitialValue {
                    return try! _CodableToNSAttributeCoder<Value>.decode(
                        from: object,
                        forKey: key,
                        defaultValue: .init(wrappedValue)
                    )
                    .value
                } else {
                    return try! _CodableToNSAttributeCoder<Value>.decode(
                        from: object,
                        forKey: key
                    )
                    .value
                }
            },
            encodeImpl: { object, key, newValue in
                try! _CodableToNSAttributeCoder(newValue).encode(
                    to: object,
                    forKey: key
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
        let hasInitialValue = (wrappedValue as? _opaque_Optional)?.isNotNil ?? true
        
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                if hasInitialValue {
                    return try Value.decode(from: object, forKey: key, defaultValue: wrappedValue)
                } else {
                    return try Value.decode(from: object, forKey: key)
                }
            },
            encodeImpl: { object, key, newValue in
                try newValue.encode(to: object, forKey: key)
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
        let hasInitialValue = (wrappedValue as? _opaque_Optional)?.isNotNil ?? true
        
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                if hasInitialValue {
                    return try Value.decode(from: object, forKey: key, defaultValue: wrappedValue)
                } else {
                    return try Value.decode(from: object, forKey: key)
                }
            },
            encodeImpl: { object, key, newValue in
                try newValue.encode(to: object, forKey: key)
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
