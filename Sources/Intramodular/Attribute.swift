//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

public protocol opaque_Attribute {
    var name: String? { get set }
    var type: EntityAttributeTypeDescription { get }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    var allowsExternalBinaryDataStorage: Bool { get }
    var preservesValueInHistoryOnDeletion: Bool { get }
}

@propertyWrapper
public struct Attribute<Value: Codable>: opaque_Attribute {
    @usableFromInline
    var parent: NSManagedObject?
    
    @usableFromInline
    let decodeImpl: (NSManagedObject, AnyStringKey) throws -> Value
    @usableFromInline
    let encodeImpl: (NSManagedObject, AnyStringKey, Value) throws -> Void
    
    public var name: String?
    public let type: EntityAttributeTypeDescription = .transformable(class: NSDictionary.self)
    public let isOptional: Bool
    public var isTransient: Bool = false
    public var allowsExternalBinaryDataStorage: Bool = false
    public var preservesValueInHistoryOnDeletion: Bool = false
    
    public var wrappedValue: Value {
        get {
            try! decodeImpl(parent.unwrap(), .init(stringValue: name.unwrap()))
        } nonmutating set {
            try! encodeImpl(parent.unwrap(), .init(stringValue: name.unwrap()), newValue)
        }
    }
}

extension Attribute {
    public init(
        wrappedValue: Value,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) {
        self.decodeImpl = { parent, name in
            try! _CodableToNSAttributeCoder<Value>.decode(
                from: parent,
                forKey: name,
                defaultValue: wrappedValue
            )
            .value
        }
        
        self.encodeImpl = { parent, name, newValue in
            try! _CodableToNSAttributeCoder(newValue).encode(
                to: parent,
                forKey: name
            )
        }
        
        self.isOptional = false
        self.isTransient = isTransient
        self.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        self.preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
    }
    
    public init<T>(
        initialValue: Value = nil,
        isTransient: Bool = false,
        allowsExternalBinaryDataStorage: Bool = false,
        preservesValueInHistoryOnDeletion: Bool = false
    ) where Value == Optional<T> {
        self.decodeImpl = { parent, name in
            try! _OptionalCodableToNSAttributeCoder<T>.decode(
                from: parent,
                forKey: name
            )
            .value ?? initialValue
        }
        
        self.encodeImpl = { parent, name, newValue in
            try! _OptionalCodableToNSAttributeCoder(newValue).encode(
                to: parent,
                forKey: name
            )
        }
        
        self.isOptional = true
        self.isTransient = isTransient
        self.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        self.preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
    }
}

// MARK: - Auxiliary Implementation -

extension EntityAttributeDescription {
    public init(_ attribute: opaque_Attribute) {
        self = EntityAttributeDescription(name: attribute.name!.stringValue)
            .type(attribute.type)
            .optional(attribute.isOptional)
            .transient(attribute.isTransient)
            .allowsExternalBinaryDataStorage(attribute.allowsExternalBinaryDataStorage)
            .preservesValueInHistoryOnDeletion(attribute.preservesValueInHistoryOnDeletion)
    }
}

extension NSAttributeDescription {
    public convenience init(_ attribute: opaque_Attribute) {
        self.init(EntityAttributeDescription(attribute))
    }
}
