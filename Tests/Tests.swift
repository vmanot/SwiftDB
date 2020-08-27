//
// Copyright (c) Vatsal Manot
//

@testable import SwiftDB

import XCTest

class Foo: Entity, Codable {
    @Attribute var x: Int = 0
    
    required init() {
        
    }
}

final class SwiftDBTests: XCTestCase {
    func testRuntime() {
        try! JSONDecoder().decode(Foo.self, from: try! JSONEncoder().encode(Foo()))
    }
}
