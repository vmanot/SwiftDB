//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

extension _CoreData.Database {
    final class MigrationManager: NSMigrationManager, ProgressReporting {
        let progress: Progress
        
        override func didChangeValue(forKey key: String) {
            super.didChangeValue(forKey: key)
            
            if key == #keyPath(NSMigrationManager.migrationProgress) {
                self.progress.completedUnitCount = max(
                    progress.completedUnitCount,
                    Int64(Float(progress.totalUnitCount) * self.migrationProgress)
                )
            }
        }
        
        init(
            sourceModel: NSManagedObjectModel,
            destinationModel: NSManagedObjectModel,
            progress: Progress
        ) {
            self.progress = progress
            
            super.init(sourceModel: sourceModel, destinationModel: destinationModel)
        }
    }
}


extension _CoreData.Database {
    struct CreateNSMappingModel {
        let mappingModel: CustomSchemaMappingModel
        
        struct Output {
            let sourceMOM: NSManagedObjectModel
            let destinationMOM: NSManagedObjectModel
            let mappingModel: NSMappingModel
        }
        
        func callAsFunction() throws -> Output {
            let result = NSMappingModel()
            
            func expression(forSource sourceEntity: NSEntityDescription) -> NSExpression {
                
                return NSExpression(format: "FETCH(FUNCTION($\(NSMigrationManagerKey), \"fetchRequestForSourceEntityNamed:predicateString:\" , \"\(sourceEntity.name!)\", \"\(NSPredicate(value: true))\"), FUNCTION($\(NSMigrationManagerKey), \"\(#selector(getter: NSMigrationManager.sourceContext))\"), \(false))")
            }
            
            let sourceMOM = try NSManagedObjectModel(mappingModel.source)
            let destinationMOM = try NSManagedObjectModel(mappingModel.source)
            
            let sourceEntitiesByID = mappingModel.source.entities.groupFirstOnly(by: \.id)
            let destinationEntitiesByID = mappingModel.destination.entities.groupFirstOnly(by: \.id)
            
            var entityMappings: [NSEntityMapping] = []
            
            for case .deleteEntity(let source) in mappingModel.mappings[.delete, default: []] {
                let sourceEntity = sourceEntitiesByID[source]!
                let coreDataEntity = try sourceMOM.entitiesByName[sourceEntity.name].unwrap()
                
                let entityMapping = NSEntityMapping()
                entityMapping.sourceEntityName = sourceEntity.name
                entityMapping.sourceEntityVersionHash = sourceMOM.entityVersionHashesByName[sourceEntity.name]
                entityMapping.mappingType = .removeEntityMappingType
                entityMapping.sourceExpression = expression(forSource: coreDataEntity)
                
                entityMappings.append(entityMapping)
            }
            
            for case .insertEntity(let destination) in mappingModel.mappings[.insert, default: []] {
                let destinationEntity = destinationEntitiesByID[destination]!
                let coreDataEntity = try destinationMOM.entitiesByName[destinationEntity.name].unwrap()
                
                let entityMapping = NSEntityMapping()
                entityMapping.destinationEntityName = destinationEntity.name
                entityMapping.destinationEntityVersionHash = destinationMOM.entityVersionHashesByName[destinationEntity.name]
                entityMapping.mappingType = .addEntityMappingType
                
                entityMapping.attributeMappings = autoreleasepool { () -> [NSPropertyMapping] in
                    var attributeMappings: [NSPropertyMapping] = []
                    for (_, destinationAttribute) in coreDataEntity.attributesByName {
                        let propertyMapping = NSPropertyMapping()
                        propertyMapping.name = destinationAttribute.name
                        attributeMappings.append(propertyMapping)
                    }
                    return attributeMappings
                }
                
                entityMapping.relationshipMappings = autoreleasepool { () -> [NSPropertyMapping] in
                    var relationshipMappings: [NSPropertyMapping] = []
                    for (_, destinationRelationship) in coreDataEntity.relationshipsByName {
                        let propertyMapping = NSPropertyMapping()
                        propertyMapping.name = destinationRelationship.name
                        relationshipMappings.append(propertyMapping)
                    }
                    return relationshipMappings
                }
                
                entityMappings.append(entityMapping)
            }
            
            for case .copyEntity(let source, let destination) in mappingModel.mappings[.copy, default: []] {
                
                let sourceSchemaEntity = sourceEntitiesByID[source]!
                let destinationSchemaEntity = destinationEntitiesByID[destination]!
                
                let sourceEntity: NSEntityDescription = try sourceMOM.entitiesByName[sourceSchemaEntity.name].unwrap()
                let destinationEntity: NSEntityDescription = try destinationMOM.entitiesByName[destinationSchemaEntity.name].unwrap()
                
                let entityMapping = NSEntityMapping()
                entityMapping.sourceEntityName = sourceEntity.name
                entityMapping.sourceEntityVersionHash = sourceEntity.versionHash
                entityMapping.destinationEntityName = destinationEntity.name
                entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
                entityMapping.mappingType = .copyEntityMappingType
                entityMapping.sourceExpression = expression(forSource: sourceEntity)
                entityMapping.attributeMappings = autoreleasepool { () -> [NSPropertyMapping] in
                    
                    let sourceAttributes = sourceEntity.cs_resolveAttributeNames()
                    let destinationAttributes = destinationEntity.cs_resolveAttributeRenamingIdentities()
                    
                    var attributeMappings: [NSPropertyMapping] = []
                    for (renamingIdentifier, destination) in destinationAttributes {
                        
                        let sourceAttribute = sourceAttributes[renamingIdentifier]!.attribute
                        let destinationAttribute = destination.attribute
                        let propertyMapping = NSPropertyMapping()
                        propertyMapping.name = destinationAttribute.name
                        propertyMapping.valueExpression = NSExpression(format: "FUNCTION($\(NSMigrationSourceObjectKey), \"\(#selector(NSManagedObject.value(forKey:)))\", \"\(sourceAttribute.name)\")")
                        attributeMappings.append(propertyMapping)
                    }
                    return attributeMappings
                }
                entityMapping.relationshipMappings = autoreleasepool { () -> [NSPropertyMapping] in
                    
                    let sourceRelationships = sourceEntity.cs_resolveRelationshipNames()
                    let destinationRelationships = destinationEntity.cs_resolveRelationshipRenamingIdentities()
                    var relationshipMappings: [NSPropertyMapping] = []
                    for (renamingIdentifier, destination) in destinationRelationships {
                        
                        let sourceRelationship = sourceRelationships[renamingIdentifier]!.relationship
                        let destinationRelationship = destination.relationship
                        let sourceRelationshipName = sourceRelationship.name
                        
                        let propertyMapping = NSPropertyMapping()
                        propertyMapping.name = destinationRelationship.name
                        propertyMapping.valueExpression = NSExpression(format: "FUNCTION($\(NSMigrationManagerKey), \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\", \"\(sourceRelationshipName)\", FUNCTION($\(NSMigrationSourceObjectKey), \"\(#selector(NSManagedObject.value(forKey:)))\", \"\(sourceRelationshipName)\"))")
                        relationshipMappings.append(propertyMapping)
                    }
                    return relationshipMappings
                }
                entityMappings.append(entityMapping)
            }
            for case .transformEntity(let source, let destination, let transformer) in mappingModel.mappings[.transform, default: []] {
                
                let sourceSchemaEntity = sourceEntitiesByID[source]!
                let destinationSchemaEntity = destinationEntitiesByID[destination]!
                
                let sourceEntity: NSEntityDescription = try sourceMOM.entitiesByName[sourceSchemaEntity.name].unwrap()
                let destinationEntity: NSEntityDescription = try destinationMOM.entitiesByName[destinationSchemaEntity.name].unwrap()
                
                let entityMapping = NSEntityMapping()
                entityMapping.sourceEntityName = sourceEntity.name
                entityMapping.sourceEntityVersionHash = sourceEntity.versionHash
                entityMapping.destinationEntityName = destinationEntity.name
                entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
                entityMapping.mappingType = .customEntityMappingType
                entityMapping.sourceExpression = expression(forSource: sourceEntity)
                entityMapping.entityMigrationPolicyClassName = NSStringFromClass(CustomEntityMigrationPolicy.self)
                
                var migrationPolicyConfiguration = CustomEntityMigrationPolicy.Configuration(
                    databaseContext: .init(
                        runtime: try _Default_SwiftDB_Runtime(schema: mappingModel.destination),
                        schema: mappingModel.destination,
                        schemaAdaptor: _CoreData.DatabaseSchemaAdaptor(schema: mappingModel.destination)
                    ),
                    schemaMappingModel: mappingModel,
                    sourceEntity: sourceSchemaEntity,
                    destinationEntity: destinationSchemaEntity,
                    transformer: transformer
                )
                
                autoreleasepool {
                    
                    let sourceAttributes = sourceEntity.cs_resolveAttributeNames()
                    let destinationAttributes = destinationEntity.cs_resolveAttributeRenamingIdentities()
                    
                    let transformedRenamingIdentifiers = Set(destinationAttributes.keys)
                        .intersection(sourceAttributes.keys)
                    
                    var sourceAttributesByDestinationKey: [String: NSAttributeDescription] = [:]
                    for renamingIdentifier in transformedRenamingIdentifiers {
                        
                        let sourceAttribute = sourceAttributes[renamingIdentifier]!.attribute
                        let destinationAttribute = destinationAttributes[renamingIdentifier]!.attribute
                        sourceAttributesByDestinationKey[destinationAttribute.name] = sourceAttribute
                    }
                    
                    migrationPolicyConfiguration.sourceAttributesByDestinationKey = sourceAttributesByDestinationKey
                }
                
                entityMapping.relationshipMappings = autoreleasepool { () -> [NSPropertyMapping] in
                    
                    let sourceRelationships = sourceEntity.cs_resolveRelationshipNames()
                    let destinationRelationships = destinationEntity.cs_resolveRelationshipRenamingIdentities()
                    let transformedRenamingIdentifiers = Set(destinationRelationships.keys)
                        .intersection(sourceRelationships.keys)
                    
                    var relationshipMappings: [NSPropertyMapping] = []
                    for renamingIdentifier in transformedRenamingIdentifiers {
                        
                        let sourceRelationship = sourceRelationships[renamingIdentifier]!.relationship
                        let destinationRelationship = destinationRelationships[renamingIdentifier]!.relationship
                        let sourceRelationshipName = sourceRelationship.name
                        let destinationRelationshipName = destinationRelationship.name
                        
                        let propertyMapping = NSPropertyMapping()
                        propertyMapping.name = destinationRelationshipName
                        propertyMapping.valueExpression = NSExpression(format: "FUNCTION($\(NSMigrationManagerKey), \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\", \"\(sourceRelationshipName)\", FUNCTION($\(NSMigrationSourceObjectKey), \"\(#selector(NSManagedObject.value(forKey:)))\", \"\(sourceRelationshipName)\"))")
                        relationshipMappings.append(propertyMapping)
                    }
                    return relationshipMappings
                }
                entityMapping.userInfo = [
                    CustomEntityMigrationPolicy.UserInfoKey.configuration: migrationPolicyConfiguration
                ]
                entityMappings.append(entityMapping)
            }
            
            result.entityMappings = entityMappings
            
            return Output(sourceMOM: sourceMOM, destinationMOM: destinationMOM, mappingModel: result)
        }
    }
}

extension _CoreData.Database {
    final class CustomEntityMigrationPolicy: NSEntityMigrationPolicy {
        struct Configuration {
            let databaseContext: _CoreData.Database.Context
            let schemaMappingModel: CustomSchemaMappingModel
            let sourceEntity: _Schema.Entity
            let destinationEntity: _Schema.Entity
            let transformer: CustomEntityMapping.Transformer
            var sourceAttributesByDestinationKey: [String: NSAttributeDescription]?
        }
        
        // MARK: NSEntityMigrationPolicy
        
        override func createDestinationInstances(
            forSource sInstance: NSManagedObject,
            in mapping: NSEntityMapping,
            manager: NSMigrationManager
        ) throws {
            let userInfo = mapping.userInfo!
            let configuration = userInfo[UserInfoKey.configuration]! as! Configuration
            var destinationObject: UnsafeRecordMigrationDestination?
            
            let destinationContext = _CoreData.DatabaseRecordContext(
                databaseContext: configuration.databaseContext,
                managedObjectContext: manager.destinationContext,
                affectedStores: manager.destinationContext.persistentStoreCoordinator?.persistentStores
            )
            
            let transactionContext = DatabaseTransactionContext(
                databaseContext: configuration.databaseContext.eraseToAnyDatabaseContext(),
                transaction: _AnyDatabaseRecordContextTransaction(
                    databaseContext: configuration.databaseContext.eraseToAnyDatabaseContext(),
                    recordContext: AnyDatabaseRecordContext(erasing: destinationContext)
                )
            )
            
            let sourceEntity = try configuration.schemaMappingModel.source.entity(withName: sInstance.entity.name.unwrap())
            
            let sourceRecordContainer = _DatabaseRecordContainer(
                transactionContext: transactionContext,
                recordSchema: sourceEntity,
                record: .init(erasing: _CoreData.DatabaseRecord(rawObject: sInstance))
            )
            
            try configuration.transformer(
                .init(
                    source: sourceRecordContainer,
                    createDestination: {
                        if let destinationObject = destinationObject {
                            return destinationObject
                        }
                        
                        let destinationEntity = try configuration.schemaMappingModel.destination.entity(withName: mapping.destinationEntityName!)
                        
                        let nsManagedObject = NSEntityDescription.insertNewObject(
                            forEntityName: mapping.destinationEntityName!,
                            into: manager.destinationContext
                        )
                        
                        TODO.unimplemented
                        /*destinationObject = UnsafeRecordMigrationDestination(
                         schemaMappingModel: configuration.schemaMappingModel,
                         sourceEntity: configuration.sourceEntity,
                         destinationEntity: configuration.destinationEntity,
                         destination: AnyDatabaseRecord(erasing: _CoreData.DatabaseRecord(rawObject: nsManagedObject))
                         )
                         
                         return destinationObject!*/
                    }
                )
            )
            
            if let dInstance = try destinationObject.map({ try $0.destination.record._cast(to: _CoreData.DatabaseRecord.self) }) {
                manager.associate(
                    sourceInstance: sInstance,
                    withDestinationInstance: dInstance.rawObject,
                    for: mapping
                )
            }
        }
        
        override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
            
            try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)
        }
        
        
        fileprivate enum UserInfoKey {
            fileprivate static let configuration = "com.vmanot.SwiftDB.CustomEntityMigrationPolicy.configuration"
        }
    }
}

extension NSEntityDescription {
    
    @nonobjc
    internal func cs_resolveAttributeNames() -> [String: (attribute: NSAttributeDescription, versionHash: Data)] {
        
        return self.attributesByName.reduce(
            into: [:],
            { (result, attribute: (key: String, value: NSAttributeDescription)) in
                
                result[attribute.key] = (attribute.value, attribute.value.versionHash)
            }
        )
    }
    
    @nonobjc
    internal func cs_resolveAttributeRenamingIdentities() -> [String: (attribute: NSAttributeDescription, versionHash: Data)] {
        
        return self.attributesByName.reduce(
            into: [:],
            { (result, attribute: (key: String, value: NSAttributeDescription)) in
                
                result[attribute.value.renamingIdentifier ?? attribute.key] = (attribute.value, attribute.value.versionHash)
            }
        )
    }
    
    @nonobjc
    internal func cs_resolveRelationshipNames() -> [String: (relationship: NSRelationshipDescription, versionHash: Data)] {
        
        return self.relationshipsByName.reduce(
            into: [:],
            { (result, relationship: (key: String, value: NSRelationshipDescription)) in
                
                result[relationship.key] = (relationship.value, relationship.value.versionHash)
            }
        )
    }
    
    @nonobjc
    internal func cs_resolveRelationshipRenamingIdentities() -> [String: (relationship: NSRelationshipDescription, versionHash: Data)] {
        
        return self.relationshipsByName.reduce(
            into: [:],
            { (result, relationship: (key: String, value: NSRelationshipDescription)) in
                
                result[relationship.value.renamingIdentifier ?? relationship.key] = (relationship.value, relationship.value.versionHash)
            }
        )
    }
}
