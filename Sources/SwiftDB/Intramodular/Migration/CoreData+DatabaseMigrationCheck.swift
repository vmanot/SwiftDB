//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

extension _CoreData.Database {
    public func performMigrationCheck() async throws -> DatabaseMigrationCheck<_CoreData.Database> {
        let lastUsedSchema = try state.schemaHistory.schemas.last.unwrap()
        
        let configurationName: String? = nil
        let fileURL = try configuration.location.unwrap()
        
        guard FileManager.default.fileExists(at: fileURL) else {
            return .init(zonesToMigrate: [])
        }
        
        if try NSPersistentStoreCoordinator.isStore(
            ofType: NSSQLiteStoreType,
            at: fileURL,
            withConfigurationName: configurationName,
            compatibleWithModel: try NSManagedObjectModel(lastUsedSchema)
        ) {
            return .init(zonesToMigrate: [])
        } else {
            return DatabaseMigrationCheck(zonesToMigrate: [.init(_fileURL: fileURL)])
        }
    }
    
    public enum MigrationStrategy {
        case dropAndDelete
        case infer
    }
    
    public func migrateOnlyKnownStore(
        strategy: MigrationStrategy
    ) throws {
        let lastUsedSchema = try state.schemaHistory.schemas.last.unwrap()
        let configurationName: String? = nil
        let fileURL = try configuration.location.unwrap()
        
        switch strategy {
            case .dropAndDelete:
                try? FileManager.default.removeItem(at: fileURL)
            case .infer:
                try migrateStore(
                    ofType: NSSQLiteStoreType,
                    at: fileURL,
                    withConfigurationName: configurationName,
                    sourceSchema: lastUsedSchema,
                    destinationSchema: schema
                )
        }
    }
    
    public func migrateStore(
        ofType storeType: String,
        at fileURL: URL,
        withConfigurationName configurationName: String? = nil,
        sourceSchema: _Schema,
        destinationSchema: _Schema
    ) throws {
        let fileManager = FileManager.default
        let temporaryDirectoryURL = fileManager.temporaryDirectory
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack")
            .appendingPathComponent(ProcessInfo().globallyUniqueString)
        
        try! fileManager.createDirectory(
            at: temporaryDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let externalStorageFolderName = ".\(fileURL.deletingPathExtension().lastPathComponent)_SUPPORT"
        let temporaryExternalStorageURL = temporaryDirectoryURL.appendingPathComponent(
            externalStorageFolderName,
            isDirectory: true
        )
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(
            fileURL.lastPathComponent,
            isDirectory: false
        )
        
        let mappingModelAndMOMs = try _CoreData.Database.CreateNSMappingModel(mappingModel: .createInferredMapping(source: sourceSchema, destination: destinationSchema))()
        
        let migrationManager = _CoreData.Database.MigrationManager(
            sourceModel: mappingModelAndMOMs.sourceMOM,
            destinationModel: mappingModelAndMOMs.destinationMOM,
            progress: Progress()
        )
        
        do {
            
            try migrationManager.migrateStore(
                from: fileURL,
                sourceType: storeType,
                options: nil,
                with: mappingModelAndMOMs.mappingModel,
                toDestinationURL: temporaryFileURL,
                destinationType: storeType,
                destinationOptions: nil
            )
            /* let temporaryStorage = SQLiteStore(
             fileURL: temporaryFileURL,
             configuration: storage.configuration,
             migrationMappingProviders: storage.migrationMappingProviders,
             localStorageOptions: storage.localStorageOptions
             )
             try temporaryStorage.cs_finalizeStorageAndWait(soureModelHint: destinationModel)*/
        } catch {
            _ = try? fileManager.removeItem(at: temporaryFileURL)
            
            throw error
        }
        
        do {
            
            try fileManager.replaceItem(
                at: fileURL,
                withItemAt: temporaryFileURL,
                backupItemName: nil,
                options: [],
                resultingItemURL: nil
            )
            if fileManager.fileExists(atPath: temporaryExternalStorageURL.path) {
                let externalStorageURL = fileURL
                    .deletingLastPathComponent()
                    .appendingPathComponent(externalStorageFolderName, isDirectory: true)
                try fileManager.replaceItem(
                    at: externalStorageURL,
                    withItemAt: temporaryExternalStorageURL,
                    backupItemName: nil,
                    options: [],
                    resultingItemURL: nil
                )
            }
        } catch {
            _ = try? fileManager.removeItem(at: temporaryFileURL)
            _ = try? fileManager.removeItem(at: temporaryExternalStorageURL)
            
            throw error
        }
    }
}
