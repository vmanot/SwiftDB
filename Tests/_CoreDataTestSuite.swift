//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

import Combine
import Filesystem
import Merge

@available(iOS 15.0, *)
final class _CoreDataTestSuite: XCTestCase {
    let database = try! DatabaseContainer(
        name: "FooCoreDataDatabase",
        schema: TestORMSchema(),
        location: URL(.temporaryDirectory().appending("_CoreDataTestDB.sqlite"))
    )
        
    func testDatabaseLoad() async throws {
        try await database.load()
    }
    
    func testEntityWithComplexProperties() async throws {
        try await database.destroyAndRebuild()
        
        let foo = try database.mainContext.create(TestORMSchema.TestEntityWithComplexProperties.self)

        foo.animal = .cat
        
        try await database.save()
        
        let retrievedFoo = try await self.database.mainContext.first(TestORMSchema.TestEntityWithComplexProperties.self).unwrap()
        
        XCTAssert(retrievedFoo.animal == .cat)
        
        foo.animal = .dog
        
        XCTAssert(retrievedFoo.animal == .dog)
    }
    
    func testInstanceCreation() async throws {
        let foo = try database.mainContext.create(TestORMSchema.TestEntity.self)
        
        foo.foo += 100
        
        try await database.mainContext.save()
        
        _ = try database.mainContext.create(TestORMSchema.TestEntityWithOptionalProperties.self)
        
        try await database.mainContext.save()
    }
        
    func testInstanceRetrieval() async throws {
        let retrievedFoo = try await database.mainContext.first(TestORMSchema.TestEntity.self).unwrap()
        
        XCTAssert(retrievedFoo.foo == 100)
        
        try await (0..<1000).concurrentForEach { _ in
            _ = try await self.database.mainContext.first(TestORMSchema.TestEntity.self).unwrap()
        }

        try await database.mainContext.delete(retrievedFoo)
        try await database.mainContext.save()
    }
    
    func testDatabaseSave() async throws {
        for _ in 0..<1000 {
            try await database.mainContext.save()
        }
        
        try await (0..<1000).concurrentForEach { _ in
            try await self.database.mainContext.save()
        }
    }
    
    func testInstanceDeletion() async throws {
        let foo = try database.mainContext.create(TestORMSchema.TestEntity.self)
        
        foo.foo += 100
        
        try await database.mainContext.delete(foo)
        try await database.mainContext.save()
    }
}
