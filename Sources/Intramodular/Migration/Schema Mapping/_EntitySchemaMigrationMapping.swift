//
// Copyright (c) Vatsal Manot
//

import Swallow

public enum _EntitySchemaMigrationMapping: Hashable, TypeDiscriminable {
    public enum MappingType: Hashable {
        case delete
        case insert
        case copy
        case transform
    }
    
    public typealias Transformer = (CustomEntityTransformerArguments) throws -> Void
    
    case deleteEntity(sourceEntity: _Schema.Entity.ID)
    case insertEntity(destinationEntity: _Schema.Entity.ID)
    case copyEntity(sourceEntity: _Schema.Entity.ID, destinationEntity: _Schema.Entity.ID)
    case transformEntity(
        sourceEntity: _Schema.Entity.ID,
        destinationEntity: _Schema.Entity.ID,
        transformer: (CustomEntityTransformerArguments) throws -> Void
    )
    
    public var instanceType: MappingType {
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

extension _EntitySchemaMigrationMapping {
    fileprivate var sourceEntity: _Schema.Entity.ID? {
        switch self {
            case .deleteEntity(let sourceEntity), .copyEntity(let sourceEntity, _), .transformEntity(let sourceEntity, _, _):
                return sourceEntity
            case .insertEntity:
                return nil
        }
    }
    
    fileprivate var destinationEntity: _Schema.Entity.ID? {
        switch self {
            case .insertEntity(let destinationEntity), .copyEntity(_, let destinationEntity), .transformEntity(_, let destinationEntity, _):
                return destinationEntity
            case .deleteEntity:
                return nil
        }
    }
}

// MARK: - Supplementary API

extension _EntitySchemaMigrationMapping {
    public static func inferredTransformEntity(
        sourceEntity: _Schema.Entity.ID,
        destinationEntity: _Schema.Entity.ID
    ) -> Self {
        .transformEntity(
            sourceEntity: sourceEntity,
            destinationEntity: destinationEntity,
            transformer: inferredTransformer
        )
    }
    
    private static func inferredTransformer(_ args: CustomEntityTransformerArguments) throws -> Void {
        let destinationObject = try args.createDestination()
        
        try destinationObject.enumerateAttributes { attributes in
            if let sourceAttribute = attributes.sourceAttribute {
                destinationObject[attributes.attribute] = try args.source.decodeFieldPayload(forKey: AnyCodingKey(stringValue: sourceAttribute.name))
            }
        }
    }
}

// MARK: - Auxiliary

public struct CustomEntityTransformerArguments {
    let source: _DatabaseRecordProxy
    public let createDestination: () throws -> UnsafeRecordMigrationDestination
}
