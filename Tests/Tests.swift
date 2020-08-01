//
// Copyright (c) Vatsal Manot
//

@testable import SwiftDB

import XCTest

final class SwiftDBTests: XCTestCase {
    func testShitOut() {
        struct Foo: Entity {
            @Attribute var x: Int = 0
            @Attribute var y: Int = 0
        }
        
        struct Bar: Entity {
            typealias Parent = Foo
            
            @Attribute var x: URL? = nil
        }
        
        struct MySchema: Schema {
            var entities: Entities {
                Foo.self
                Bar.self
            }
        }
    }
}
