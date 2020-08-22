//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow
import SwiftUI

/// A property wrapper type that can read and write an attribute managed by CoreData.
@propertyWrapper
public struct Attribute<Value>: _opaque_Attribute {
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
    public let isOptional: Bool
    public var isTransient: Bool = false
    public var allowsExternalBinaryDataStorage: Bool = false
    public var preservesValueInHistoryOnDeletion: Bool = false
    
    public var wrappedValue: Value {
        get {
            try! decodeImpl(underlyingObject.unwrap(), .init(stringValue: name.unwrap()))
        } nonmutating set {
            guard underlyingObject?.managedObjectContext != nil else {
                return
            }
            
            try! encodeImpl(underlyingObject.unwrap(), .init(stringValue: name.unwrap()), newValue)
        }
    }
    
    public var projectedValue: Binding<Value> {
        .init(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
    
    public var type: EntityAttributeTypeDescription {
        if let type = Value.self as? NSPrimitiveAttributeCoder.Type {
            if let result = EntityAttributeTypeDescription(type.toNSAttributeType()) {
                return result
            }
        } else if let wrappedValue = wrappedValue as? NSAttributeCoder {
            if let result = EntityAttributeTypeDescription(wrappedValue.getNSAttributeType()) {
                return result
            }
        } else if let type = Value.self as? NSSecureCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else if let type = Value.self as? NSCoding.Type {
            return .transformable(class: type, transformerName: "NSSecureUnarchiveFromData")
        } else {
            return .transformable(class: NSDictionary.self, transformerName: "NSSecureUnarchiveFromData")
        }
        
        return .undefined
    }
    
    mutating func _runtime_encodeDefaultValueIfNecessary() {
        guard let underlyingObject = underlyingObject, let name = name else {
            return
        }
        
        if !isOptional && !underlyingObject.primitiveValueExists(forKey: name) {
            _ = self.wrappedValue // force an evaluation
        }
    }
}

// MARK: - Initialization -

extension Attribute {
    init(
        initialValue: Value?,
        decodeImpl: @escaping (NSManagedObject, AnyStringKey) throws -> Value,
        encodeImpl: @escaping (NSManagedObject, AnyStringKey, Value) throws -> Void,
        isOptional: Bool,
        isTransient: Bool,
        allowsExternalBinaryDataStorage: Bool,
        preservesValueInHistoryOnDeletion: Bool
    ) {
        self.initialValue = initialValue
        self.decodeImpl = decodeImpl
        self.encodeImpl = encodeImpl
        self.isOptional = isOptional
        self.isTransient = isTransient
        self.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        self.preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
    }
}

extension Attribute where Value: NSAttributeCoder {
    public init(
        wrappedValue: Value,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                try Value.decode(from: object, forKey: key, defaultValue: wrappedValue)
            },
            encodeImpl: { object, key, newValue in
                try newValue.encode(to: object, forKey: key)
            },
            isOptional: false,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
    public init<T>(
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value == Optional<T> {
        self.init(
            wrappedValue: nil,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: Codable {
    public init(
        wrappedValue: Value,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        self.init(
            initialValue: nil,
            decodeImpl: { object, key in
                try! _CodableToNSAttributeCoder<Value>.decode(
                    from: object,
                    forKey: key,
                    defaultValue: .init(wrappedValue)
                )
                .value
            },
            encodeImpl: { object, key, newValue in
                try! _CodableToNSAttributeCoder(newValue).encode(
                    to: object,
                    forKey: key
                )
            },
            isOptional: false,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
    
    public init<T>(
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value == Optional<T> {
        self.init(
            wrappedValue: nil,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: Codable & NSAttributeCoder {
    public init(
        wrappedValue: Value,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        self.init(
            initialValue: nil,
            decodeImpl: { object, key in
                try! _CodableToNSAttributeCoder<Value>.decode(
                    from: object,
                    forKey: key,
                    defaultValue: .init(wrappedValue)
                )
                .value
            },
            encodeImpl: { object, key, newValue in
                try! _CodableToNSAttributeCoder(newValue).encode(
                    to: object,
                    forKey: key
                )
            },
            isOptional: false,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
    
    public init<T>(
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value == Optional<T> {
        self.init(
            wrappedValue: nil,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
}

extension Attribute where Value: Codable & NSPrimitiveAttributeCoder {
    public init(
        wrappedValue: Value,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        self.init(
            initialValue: nil,
            decodeImpl: { object, key in
                try! _CodableToNSAttributeCoder<Value>.decode(
                    from: object,
                    forKey: key,
                    defaultValue: .init(wrappedValue)
                )
                .value
            },
            encodeImpl: { object, key, newValue in
                try! _CodableToNSAttributeCoder(newValue).encode(
                    to: object,
                    forKey: key
                )
            },
            isOptional: false,
            isTransient: isTransient,
            allowsExternalBinaryDataStorage: allowsExternalBinaryDataStorage,
            preservesValueInHistoryOnDeletion: preservesValueInHistoryOnDeletion
        )
    }
    
    public init<T>(
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value == Optional<T> {
        self.init(
            wrappedValue: nil,
            isTransient: isTransient,
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
            type: type,
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
