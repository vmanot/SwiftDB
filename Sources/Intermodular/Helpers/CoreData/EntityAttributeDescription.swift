//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swift

public final class EntityAttributeDescription: EntityPropertyDescription {
    public enum CodingKeys: String, CodingKey {
        case type
        case allowsExternalBinaryDataStorage
        case preservesValueInHistoryOnDeletion
    }
    
    public let type: EntityAttributeTypeDescription
    public let defaultValue: Any?
    public let allowsExternalBinaryDataStorage: Bool
    public let preservesValueInHistoryOnDeletion: Bool
    
    public init(
        name: String,
        isOptional: Bool,
        isTransient: Bool,
        renamingIdentifier: String?,
        type: EntityAttributeTypeDescription,
        defaultValue: Any?,
        allowsExternalBinaryDataStorage: Bool,
        preservesValueInHistoryOnDeletion: Bool
    ) {
        self.type = type
        self.defaultValue = defaultValue
        self.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        self.preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
        
        super.init(
            name: name,
            isOptional: isOptional,
            isTransient: isTransient,
            renamingIdentifier: renamingIdentifier
        )
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try container.decode(EntityAttributeTypeDescription.self, forKey: .type)
        self.defaultValue = nil
        self.allowsExternalBinaryDataStorage = try container.decode(Bool.self, forKey: .allowsExternalBinaryDataStorage)
        self.preservesValueInHistoryOnDeletion = try container.decode(Bool.self, forKey: .preservesValueInHistoryOnDeletion)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(allowsExternalBinaryDataStorage, forKey: .allowsExternalBinaryDataStorage)
        try container.encode(preservesValueInHistoryOnDeletion, forKey: .preservesValueInHistoryOnDeletion)
    }
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        
        hasher.combine(type)
        hasher.combine(allowsExternalBinaryDataStorage)
        hasher.combine(preservesValueInHistoryOnDeletion)
    }
    
    public override func toNSPropertyDescription() -> NSPropertyDescription {
        NSAttributeDescription(self)
    }
}

// MARK: - Auxiliary Implementation -

extension NSAttributeDescription {
    public convenience init(_ description: EntityAttributeDescription) {
        self.init()
        
        name = description.name
        isOptional = description.isOptional
        isTransient = description.isTransient
        attributeType = .init(description.type)
        
        if let attributeValueClassName = description.type.className {
            self.attributeValueClassName = attributeValueClassName
        }
        
        if let valueTransformerName = description.type.transformerName {
            self.valueTransformerName = valueTransformerName
        }
        
        allowsExternalBinaryDataStorage = description.allowsExternalBinaryDataStorage
        preservesValueInHistoryOnDeletion = description.preservesValueInHistoryOnDeletion
    }
}
