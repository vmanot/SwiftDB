//
// Copyright (c) Vatsal Manot
//

@testable import SwiftDB

import Filesystem
import Combine
import Merge
import XCTest

final class _CoreDataTestSuite: XCTestCase {
    func testRuntime() throws {
        let database = try PersistentContainer(
            name: "FooCoreDataDatabase",
            schema: TestSchema(),
            location: URL(.temporaryDirectory())
        )
        
        try database.load()
        
        let foo = try database.create(TestEntity.self)
        
        foo.foo += 100
        
        try database.save()
        try database.fetchFirst(TestEntity.self).blockAndUnwrap().unwrap().foo.printSelf()
        try database.deleteAll()
        try database.fetchAllInstances().printSelf()
        try database.save()
    }
}
