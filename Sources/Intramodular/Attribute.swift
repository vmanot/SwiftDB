//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow
import SwiftUI

/// A property wrapper type that can read and write an attribute managed by CoreData.
@propertyWrapper
public struct Attribute<Value: Codable>: _opaque_Attribute {
    var _opaque_modelEnvironment: _opaque_ModelEnvironment = .init()
    
    @usableFromInline
    var base: NSManagedObject?
    
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
            try! decodeImpl(base.unwrap(), .init(stringValue: name.unwrap()))
        } nonmutating set {
            try! encodeImpl(base.unwrap(), .init(stringValue: name.unwrap()), newValue)
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
        } else {
            return .transformable(class: NSDictionary.self, transformerName: "NSSecureUnarchiveFromData")
        }
        
        return .undefined
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

extension Attribute {
    public init(
        wrappedValue: Value,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value: NSAttributeCoder {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                try Value.decode(from: object, forKey: key, initialValue: wrappedValue)
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
    
    public init(
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value: Initiable & NSPrimitiveAttributeCoder {
        self.init(
            initialValue: .init(),
            decodeImpl: { object, key in
                try Value.decode(from: object, forKey: key)
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
        wrappedValue: T,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where T: NSAttributeCoder, Value == Optional<T> {
        self.init(
            initialValue: wrappedValue,
            decodeImpl: { object, key in
                try Value.decode(from: object, forKey: key, initialValue: wrappedValue)
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
        initialValue: Value = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where T: NSAttributeCoder, Value == Optional<T> {
        self.init(
            initialValue: initialValue,
            decodeImpl: { object, key in
                try Value.decode(from: object, forKey: key, initialValue: initialValue)
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
        initialValue: Value = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where T: NSPrimitiveAttributeCoder, Value == Optional<T> {
        self.init(
            initialValue: initialValue,
            decodeImpl: { object, key in
                try Value.decode(from: object, forKey: key, initialValue: initialValue)
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
}

extension Attribute {
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
                    defaultValue: wrappedValue
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
        initialValue: Value = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value == Optional<T> {
        self.init(
            initialValue: nil,
            decodeImpl: { object, key in
                try! _OptionalCodableToNSAttributeCoder<T>.decode(
                    from: object,
                    forKey: key
                )
                .value ?? initialValue
            },
            encodeImpl: { object, key, newValue in
                try! _OptionalCodableToNSAttributeCoder(newValue).encode(
                    to: object,
                    forKey: key
                )
            },
            isOptional: true,
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
