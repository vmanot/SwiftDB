//
// Copyright (c) Vatsal Manot
//

@testable import SwiftDB

import Filesystem
import Combine
import Merge
import XCTest

class Foo: CustomStringConvertible, Entity, Codable, ObservableObject {
    @Attribute var x: Int = 0
    
    var description: String {
        "Foo \(x)"
    }
    
    required init() {
        
    }
}

struct TestSchema: Schema {
    var body: Body {
        Foo.self
    }
}

final class SwiftDBTests: XCTestCase {
    func testRuntime() throws {
        let database = try PersistentContainer(
            name: "FooCoreDataDatabase",
            schema: TestSchema(),
            location: .filePath("/Users/vmanot/Desktop/Junk/SwiftDB-Tests/Test.sqlite")
        )
        
        try database.load()
        
        let foo = try database.create(Foo.self)
        
        foo.x += 1
        
        try database.deleteAll()
        try database.fetchAllInstances().printSelf()
        
        try database.save()
    }
}
