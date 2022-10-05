//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

import FoundationX
import Merge
import System

@available(iOS 16.0, *)
final class _CoreDataTestSuite: XCTestCase {
    public var database: DatabaseContainer<TestORMSchema> = {
        let tempDir = FilePath(URL.temporaryDirectory)!

        if FileManager.default.directoryExists(at: tempDir) {
            for suburl in try! FileManager.default.contentsOfDirectory(at: tempDir) {
                try! FileManager.default.removeItem(at: suburl)
            }

            try! FileManager.default.removeItemIfNecessary(at: tempDir)
        }

        let randomDatabaseName = UUID().uuidString

        let database = try! DatabaseContainer(
            name: randomDatabaseName,
            schema: TestORMSchema(),
            location: URL(tempDir.appending("\(randomDatabaseName).sqlite"))
        )

        return database
    }()
        
    func testDatabaseLoad() async throws {
        try await database.load()
    }

    func testInstanceCreation() async throws {
        try await database.load()
        
        let foo = try database.mainContext.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)
        
        foo.foo += 100
        
        try await database.mainContext.save()
        
        _ = try database.mainContext.create(TestORMSchema.EntityWithOptionalProperties.self)
        
        try await database.mainContext.save()
    }

    func testEntityWithComplexProperties() async throws {
        try await database.load()

        let noPreviousInstancesExist = try await database.mainContext.first(TestORMSchema.EntityWithComplexProperties.self) == nil

        XCTAssert(noPreviousInstancesExist)

        let foo = try database.mainContext.create(TestORMSchema.EntityWithComplexProperties.self)

        foo.animal = .cat

        try await database.save()

        let retrievedFoo = try await self.database.mainContext.first(TestORMSchema.EntityWithComplexProperties.self).unwrap()

        XCTAssert(retrievedFoo.animal == .cat)

        foo.animal = .dog

        XCTAssert(retrievedFoo.animal == .dog)
    }

    func testEntityWithDynamicProperties() async throws {
        try await database.load()

        let foo = try database.mainContext.create(TestORMSchema.EntityWithDynamicProperties.self)
        let newFoo = try database.mainContext.create(TestORMSchema.EntityWithDynamicProperties.self)

        XCTAssert(foo.id != newFoo.id)
        XCTAssert(foo.defaultValueID == newFoo.defaultValueID)
    }

    func testInstanceRetrieval() async throws {
        try await database.load()

        let foo = try database.mainContext.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)

        foo.foo += 100

        try await database.mainContext.save()

        let retrievedFoo = try await database.mainContext.first(TestORMSchema.EntityWithSimpleRequiredProperty.self).unwrap()
        
        XCTAssert(retrievedFoo.foo == 100)
        
        try await (0..<1000).concurrentForEach { _ in
            _ = try await self.database.mainContext.first(TestORMSchema.EntityWithSimpleRequiredProperty.self).unwrap()
        }

        try await database.mainContext.delete(retrievedFoo)
        try await database.mainContext.save()
    }
    
    func testDatabaseSave() async throws {
        try await database.load()

        for _ in 0..<1000 {
            _ = try database.mainContext.create(TestORMSchema.EmptyEntity.self)

            try await database.mainContext.save()
        }
        
        try await (0..<1000).concurrentForEach { _ in
            _ = try self.database.mainContext.create(TestORMSchema.EmptyEntity.self)

            try await self.database.mainContext.save()
        }
    }
    
    func testInstanceDeletion() async throws {
        try await database.load()

        let foo = try database.mainContext.create(TestORMSchema.EntityWithSimpleRequiredProperty.self)
        
        foo.foo += 100
        
        try await database.mainContext.delete(foo)
        try await database.mainContext.save()
    }
}

@available(iOS 16.0, *)
extension _CoreDataTestSuite {
    func testRelationships() async throws {
        try await database.load()
        
        let schemaEntity = try database.schema.entity(forModelType: TestORMSchema.ChildParentEntity.self).unwrap()
        
        guard let property = schemaEntity.properties.first(where: { $0.name == "parent" }) as? _Schema.Entity.Relationship else {
            XCTFail()
            return
        }
        
        print(property.relationshipConfiguration.cardinality)
        XCTAssert(property.relationshipConfiguration.cardinality == .manyToOne)
        
        let parent = try database.mainContext.create(TestORMSchema.ChildParentEntity.self)
        
        for _ in 0..<10 {
            let child = try database.mainContext.create(TestORMSchema.ChildParentEntity.self)
            
            parent.children.insert(child)
        }
        
        XCTAssert(Array(parent.children).count == 10)
    }
}
