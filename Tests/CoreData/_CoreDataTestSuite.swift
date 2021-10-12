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
            location: .filePath("/Users/vmanot/Desktop/Junk/SwiftDB-Tests/Test.sqlite")
        )
        
        try database.load()
        
        let foo = try database.create(FooEntity.self)
        
        foo.x += 100
        
        try database.save()
        
        try database.fetchFirst(FooEntity.self).blockAndUnwrap().unwrap().x.printSelf()
        
        try database.deleteAll()
        try database.fetchAllInstances().printSelf()
        
        try database.save()
    }
}
