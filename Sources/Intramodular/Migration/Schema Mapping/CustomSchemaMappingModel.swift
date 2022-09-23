//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct CustomSchemaMappingModel {
    public let source: DatabaseSchema
    public let destination: DatabaseSchema
    public let mappings: [CustomEntityMapping.MappingType: [CustomEntityMapping]]
    
    public init(
        source: DatabaseSchema,
        destination: DatabaseSchema,
        mappings: [CustomEntityMapping]
    ) {
        self.source = source
        self.destination = destination
        self.mappings = mappings.group(by: \.type)
    }
}

// MARK: - Supplementary API -

extension CustomSchemaMappingModel {
    public static func createInferredMapping(
        source: DatabaseSchema,
        destination: DatabaseSchema
    ) -> Self {
        CustomSchemaMappingModel(
            source: source,
            destination: destination,
            mappings: Self.resolveEntityMappings(source: source, destination: destination)
        )
    }
}

extension CustomSchemaMappingModel {
    private static func resolveEntityMappings(
        source: DatabaseSchema,
        destination: DatabaseSchema,
        entityMappings: [CustomEntityMapping] = []
    ) -> [CustomEntityMapping] {
        var deleteMappings: Set<CustomEntityMapping> = []
        var insertMappings: Set<CustomEntityMapping> = []
        var copyMappings: Set<CustomEntityMapping> = []
        var transformMappings: Set<CustomEntityMapping> = []
        var allMappedSourceKeys: [DatabaseSchema.Entity.ID: DatabaseSchema.Entity.ID] = [:]
        var allMappedDestinationKeys: [DatabaseSchema.Entity.ID: DatabaseSchema.Entity.ID] = [:]
        
        let sourceIDs = source.entities.groupFirstOnly(by: \.id)
        let destinationIDs = destination.entities.groupFirstOnly(by: \.id)
        
        let removedIDs = Set(sourceIDs.keys)
            .subtracting(destinationIDs.keys)
        let addedIDs = Set(destinationIDs.keys)
            .subtracting(sourceIDs.keys)
        let transformedIDs = Set(destinationIDs.keys)
            .subtracting(addedIDs)
            .subtracting(removedIDs)
        
        for mapping in entityMappings {
            switch mapping {
                case .deleteEntity(let sourceEntity):
                    deleteMappings.insert(mapping)
                    allMappedSourceKeys[sourceEntity] = .unavailable
                case .insertEntity(let destinationEntity):
                    insertMappings.insert(mapping)
                    allMappedDestinationKeys[destinationEntity] = .unavailable
                case .transformEntity(let sourceEntity, let destinationEntity, _):
                    transformMappings.insert(mapping)
                    allMappedSourceKeys[sourceEntity] = destinationEntity
                    allMappedDestinationKeys[destinationEntity] = sourceEntity
                case .copyEntity(let sourceEntity, let destinationEntity):
                    copyMappings.insert(mapping)
                    allMappedSourceKeys[sourceEntity] = destinationEntity
                    allMappedDestinationKeys[destinationEntity] = sourceEntity
            }
        }
        
        for id in transformedIDs {
            let sourceEntity = sourceIDs[id]!
            let destinationEntity = destinationIDs[id]!
            
            switch (allMappedSourceKeys[sourceEntity.id], allMappedDestinationKeys[destinationEntity.id]) {
                case (nil, nil):
                    /* if sourceEntity.versionHash == destinationEntity.versionHash {
                     copyMappings.insert(
                     .copyEntity(
                     sourceEntity: sourceEntityName,
                     destinationEntity: destinationEntityName
                     )
                     )
                     } else {
                     transformMappings.insert(
                     .transformEntity(
                     sourceEntity: sourceEntityName,
                     destinationEntity: destinationEntityName,
                     transformer: CustomMapping.inferredTransformation
                     )
                     )
                     }*/
                    transformMappings.insert(
                        .inferredTransformEntity(
                            sourceEntity: sourceEntity.id,
                            destinationEntity: destinationEntity.id
                        )
                    )
                    
                    allMappedSourceKeys[sourceEntity.id] = destinationEntity.id
                    allMappedDestinationKeys[destinationEntity.id] = sourceEntity.id
                    
                case (.unavailable?, nil):
                    insertMappings.insert(.insertEntity(destinationEntity: destinationEntity.id))
                    allMappedDestinationKeys[destinationEntity.id] = .unavailable
                    
                case (nil, .unavailable?):
                    deleteMappings.insert(.deleteEntity(sourceEntity: sourceEntity.id))
                    allMappedSourceKeys[sourceEntity.id] = .unavailable
                    
                default:
                    continue
            }
        }
        
        for id in removedIDs {
            let sourceEntity = sourceIDs[id]!
            
            switch allMappedSourceKeys[sourceEntity.id] {
                case nil:
                    deleteMappings.insert(.deleteEntity(sourceEntity: sourceEntity.id))
                    allMappedSourceKeys[sourceEntity.id] = .unavailable
                default:
                    continue
            }
        }
        
        for id in addedIDs {
            let destinationEntity = destinationIDs[id]!
            
            switch allMappedDestinationKeys[destinationEntity.id] {
                case nil:
                    insertMappings.insert(.insertEntity(destinationEntity: destinationEntity.id))
                    allMappedDestinationKeys[destinationEntity.id] = .unavailable
                default:
                    continue
            }
        }
        
        var mappings: Set<CustomEntityMapping> = []
        
        mappings.formUnion(deleteMappings)
        mappings.formUnion(insertMappings)
        mappings.formUnion(copyMappings)
        mappings.formUnion(transformMappings)
        
        return Array(mappings)
    }
}
