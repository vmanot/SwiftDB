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
    public let allowsExternalBinaryDataStorage: Bool
    public let preservesValueInHistoryOnDeletion: Bool
    
    public init(
        name: String,
        isOptional: Bool,
        isTransient: Bool,
        type: EntityAttributeTypeDescription,
        allowsExternalBinaryDataStorage: Bool,
        preservesValueInHistoryOnDeletion: Bool
    ) {
        self.type = type
        self.allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        self.preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
        
        super.init(name: name, isOptional: isOptional, isTransient: isTransient)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try container.decode(EntityAttributeTypeDescription.self, forKey: .type)
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
        
        switch description.type {
            case .undefined:
                attributeType = .undefinedAttributeType
            case .integer16:
                attributeType = .integer16AttributeType
            case .integer32:
                attributeType = .integer32AttributeType
            case .integer64:
                attributeType = .integer64AttributeType
            case .decimal:
                attributeType = .decimalAttributeType
            case .double:
                attributeType = .doubleAttributeType
            case .float:
                attributeType = .floatAttributeType
            case .string:
                attributeType = .stringAttributeType
            case .boolean:
                attributeType = .booleanAttributeType
            case .date:
                attributeType = .dateAttributeType
            case .binaryData:
                attributeType = .binaryDataAttributeType
            case .UUID:
                attributeType = .UUIDAttributeType
            case .URI:
                attributeType = .URIAttributeType
            case let .transformable(className, transformerName):
                attributeType = .transformableAttributeType
                attributeValueClassName = className
                valueTransformerName = transformerName
            case .objectID:
                attributeType = .objectIDAttributeType
        }
        
        allowsExternalBinaryDataStorage = allowsExternalBinaryDataStorage
        preservesValueInHistoryOnDeletion = preservesValueInHistoryOnDeletion
    }
}
