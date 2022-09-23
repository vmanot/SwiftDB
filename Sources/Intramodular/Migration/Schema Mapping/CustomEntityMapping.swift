//
// Copyright (c) Vatsal Manot
//

import Swallow

public enum CustomEntityMapping: Hashable, TypeDiscriminable {
    public enum MappingType: Hashable {
        case delete
        case insert
        case copy
        case transform
    }
    
    public typealias Transformer = (CustomEntityTransformerArguments) throws -> Void
    
    case deleteEntity(sourceEntity: DatabaseSchema.Entity.ID)
    case insertEntity(destinationEntity: DatabaseSchema.Entity.ID)
    case copyEntity(sourceEntity: DatabaseSchema.Entity.ID, destinationEntity: DatabaseSchema.Entity.ID)
    case transformEntity(
        sourceEntity: DatabaseSchema.Entity.ID,
        destinationEntity: DatabaseSchema.Entity.ID,
        transformer: (CustomEntityTransformerArguments) throws -> Void
    )
    
    public var type: MappingType {
        switch self {
            case .deleteEntity:
                return .delete
            case .insertEntity:
                return .insert
            case .copyEntity:
                return .copy
            case .transformEntity:
                return .transform
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
            case .deleteEntity(let sourceEntity):
                hasher.combine(0)
                hasher.combine(sourceEntity)
            case .insertEntity(let destinationEntity):
                hasher.combine(1)
                hasher.combine(destinationEntity)
            case .copyEntity(let sourceEntity, let destinationEntity):
                hasher.combine(2)
                hasher.combine(sourceEntity)
                hasher.combine(destinationEntity)
            case .transformEntity(let sourceEntity, let destinationEntity, _): // FIXME?
                hasher.combine(3)
                hasher.combine(sourceEntity)
                hasher.combine(destinationEntity)
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension CustomEntityMapping {
    fileprivate var sourceEntity: DatabaseSchema.Entity.ID? {
        switch self {
            case .deleteEntity(let sourceEntity), .copyEntity(let sourceEntity, _), .transformEntity(let sourceEntity, _, _):
                return sourceEntity
            case .insertEntity:
                return nil
        }
    }
    
    fileprivate var destinationEntity: DatabaseSchema.Entity.ID? {
        switch self {
            case .insertEntity(let destinationEntity), .copyEntity(_, let destinationEntity), .transformEntity(_, let destinationEntity, _):
                return destinationEntity
            case .deleteEntity:
                return nil
        }
    }
}

// MARK: - Supplementary API -

extension CustomEntityMapping {
    public static func inferredTransformEntity(
        sourceEntity: DatabaseSchema.Entity.ID,
        destinationEntity: DatabaseSchema.Entity.ID
    ) -> Self {
        .transformEntity(
            sourceEntity: sourceEntity,
            destinationEntity: destinationEntity,
            transformer: inferredTransformer
        )
    }
    
    private static func inferredTransformer(_ args: CustomEntityTransformerArguments) throws -> Void {
        let destinationObject = args.createDestination()
        
        try destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
            if let sourceAttribute = sourceAttribute {
                destinationObject[attribute] = try args.source.unsafeDecodeValue(forKey: AnyStringKey(stringValue: sourceAttribute.name))
            }
        }
    }
}

// MARK: - Auxiliary Implementation -

public struct CustomEntityTransformerArguments {
    public let source: AnyDatabaseRecord
    public let createDestination: () -> UnsafeRecordMigrationDestination
}
