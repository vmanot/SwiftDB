//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB
import SwiftData
final class RuntimeTests: XCTestCase {
    let runtime = try! _SwiftDB_DefaultRuntime(schema: _Schema(TestORMSchema()))

    func testEntityLookup() {
        XCTAssert(runtime.metatype(forEntityNamed: "EntityWithSimpleRequiredProperty")?.value == TestORMSchema.EntityWithSimpleRequiredProperty.self)
    }

    func testEntityKeyPathToStringConversion() async throws {
        let fooKeyPath = try runtime.convertEntityKeyPathToString(\TestORMSchema.EntityWithSimpleRequiredProperty.foo)

        XCTAssert(fooKeyPath == "foo")

        XCTAssertThrowsError(try runtime.convertEntityKeyPathToString(\TestORMSchema.EntityWithSimpleRequiredProperty.foo.description))
    }
}
