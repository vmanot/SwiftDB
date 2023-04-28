//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

import FoundationX
import Merge
import System

final class _CoreDataTestSuite: XCTestCase {
    public var database: LocalDatabaseContainer<TestORMSchema> = {
        _CoreDataTestSuite.createTestDatabase()
    }()
    
    func testDatabaseLoad() async throws {
        try await database.load()
    }
    
    func testInstanceCreation() async throws {
        try await database.load()
        
        try await database.transact { transaction in
            let foo = try transaction.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)
            
            foo.foo += 100
            
            _ = try transaction.create(TestORMSchema.EntityWithOptionalProperties.self)
        }
    }
    
    func testEntityWithComplexProperties() async throws {
        try await database.load()
        
        try await database.transact { transaction in
            let noPreviousInstancesExist = try transaction.first(TestORMSchema.EntityWithComplexProperties.self) == nil
            
            XCTAssert(noPreviousInstancesExist)
            
            let foo = try transaction.create(TestORMSchema.EntityWithComplexProperties.self)
            
            foo.animal = .dog
        }
        
        try await database.transact { transaction in
            let foo = try transaction.first(TestORMSchema.EntityWithComplexProperties.self).unwrap()
            
            XCTAssert(foo.animal == .dog)
            
            foo.animal = .lion
            
            XCTAssert(foo.animal == .lion)
        }
    }
    
    func testEntityWithDynamicProperties() async throws {
        try await database.load()
        
        try await database.transact { transaction in
            let foo = try transaction.create(TestORMSchema.EntityWithDynamicProperties.self)
            let newFoo = try transaction.create(TestORMSchema.EntityWithDynamicProperties.self)
            
            XCTAssert(foo.id != newFoo.id)
            XCTAssert(foo.defaultValueID == newFoo.defaultValueID)
        }
    }
    
    func testInstanceRetrieval() async throws {
        try await database.load()
        
        try await database.transact { transaction in
            let foo = try transaction.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)
            
            foo.foo += 100
            
            let retrievedFoo = try transaction.first(TestORMSchema.EntityWithSimpleRequiredProperty.self).unwrap()
            
            XCTAssert(retrievedFoo.foo == 100)
            
            try (0..<1000).forEach { _ in
                _ = try transaction.first(TestORMSchema.EntityWithSimpleRequiredProperty.self).unwrap()
            }
            
            try transaction.delete(retrievedFoo)
        }
    }
    
    func testDatabaseSave() async throws {
        try await database.load()
        
        for _ in 0..<1000 {
            try await database.transact { transaction in
                _ = try transaction.create(TestORMSchema.EmptyEntity.self)
            }
        }
        
        try await (0..<1000).concurrentForEach { _ in
            try await self.database.transact { transaction in
                _ = try transaction.create(TestORMSchema.EmptyEntity.self)
            }
        }
    }
    
    func testInstanceDeletion() async throws {
        try await database.load()
        
        try await database.transact { transaction in
            let foo = try transaction.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)
            
            foo.foo += 100
            
            try transaction.delete(foo)
        }
    }
    
    func testQuerySubscription() async throws {
        try await database.load()
        
        let numberOfEvents = ActorIsolated(value: 0)
        
        let subscription = try await database.querySubscription(for: QueryRequest<TestORMSchema.EntityWithSimpleRequiredProperty>())
        
        let countTask = Task {
            for await _ in subscription.discardError().values.prefix(4) {
                await numberOfEvents.mutate {
                    $0 += 1
                }
            }
        }
        
        try await Task.sleep(.seconds(1))
        
        try await database.transact { transaction in
            _ = try transaction.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)
        }
        
        try await database.transact { transaction in
            let instance = try transaction.first(TestORMSchema.EntityWithSimpleRequiredProperty.self)!
            
            instance.foo += 1
        }
        
        try await database.transact { transaction in
            let instance = try transaction.first(TestORMSchema.EntityWithSimpleRequiredProperty.self)!
            
            try transaction.delete(instance)
        }
        
        await countTask.value
        
        let numEvents = await numberOfEvents.value
        
        XCTAssertEqual(numEvents, 4)
    }
}

extension _CoreDataTestSuite {
    func testRelationships() async throws {
        try await database.load()
        
        let schemaEntity = try database.schema.entity(forModelType: TestORMSchema.ChildParentEntity.self).unwrap()
        
        guard let property = schemaEntity.properties.first(where: { $0.name == "parent" }) as? _Schema.Entity.Relationship else {
            XCTFail()
            return
        }
        
        XCTAssert(property.relationshipConfiguration.cardinality == .manyToOne)
        
        try await database.transact { transaction in
            let parent = try transaction.create(TestORMSchema.ChildParentEntity.self)
            
            for _ in 0..<10 {
                let child = try transaction.create(TestORMSchema.ChildParentEntity.self)
                
                parent.children.insert(child)
            }
            
            XCTAssert(parent.children.count == 10)
        }
    }
}

extension _CoreDataTestSuite {
    private static func createTestDatabase() -> LocalDatabaseContainer<TestORMSchema> {
        let randomDatabaseName = UUID().uuidString
        let tempDir = URL.temporaryDirectory.appending(component: randomDatabaseName, directoryHint: .isDirectory)
        
        if FileManager.default.directoryExists(at: tempDir) {
            for suburl in try! FileManager.default.contentsOfDirectory(at: tempDir) {
                try! FileManager.default.removeItem(at: suburl)
            }
            
            try! FileManager.default.removeItemIfNecessary(at: tempDir)
        }
        
        try! FileManager.default.createDirectoryIfNecessary(at: tempDir)
        
        let database = try! LocalDatabaseContainer(
            name: randomDatabaseName,
            schema: TestORMSchema(),
            location: tempDir.appending(component: "test.sqlite", directoryHint: .notDirectory)
        )
        
        return database
    }
}
