//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

final class RuntimeTests: XCTestCase {
    let runtime = _Default_SwiftDB_Runtime()
    
    func testEntityKeyPathToStringConversion() async throws {
        let fooKeyPath = try runtime.convertEntityKeyPathToString(\TestORMSchema.TestEntity.foo)
        
        XCTAssert(fooKeyPath == "foo")
        
        let fooDescriptionKeyPath = try? runtime.convertEntityKeyPathToString(\TestORMSchema.TestEntity.foo.description)
        
        XCTAssert(fooDescriptionKeyPath == nil)
    }
}
