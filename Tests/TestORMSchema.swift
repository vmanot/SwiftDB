//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

struct TestORMSchema: Schema {
    var body: Body {
        TestEntity.self
    }
}

extension TestORMSchema {
    class TestEntity: Entity, Codable {
        @Attribute var foo: Int = 0
        
        required init() {
            
        }
    }
}
