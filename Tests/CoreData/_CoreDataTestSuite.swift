//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

import Combine
import Filesystem
import Merge

final class _CoreDataTestSuite: XCTestCase {
    func testRuntime() throws {
        let database = try DatabaseContainer(
            name: "FooCoreDataDatabase",
            schema: TestSchema(),
            location: URL(.temporaryDirectory())
        )
        
        try database.load()
        
        let foo = try database.create(TestEntity.self)
        
        foo.foo += 100
        
        try database.save()
        try database.fetchFirst(TestEntity.self).blockAndUnwrap().unwrap()
        try database.deleteAllInstances()
        try database.save()
    }
}
