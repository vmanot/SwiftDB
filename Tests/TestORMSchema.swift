//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

struct TestORMSchema: Schema {
    var body: Body {
        TestEntity.self
        TestEntityWithOptionalProperties.self
    }
}

extension TestORMSchema {
    class TestEntity: Entity, Codable {
        @Attribute var foo: Int = 0
        
        required init() {
            
        }
    }
    
    class TestEntityWithOptionalProperties: Entity, Codable {
        @Attribute var foo: Int? = nil
        @Attribute var bar: Date? = nil
        @Attribute var baz: String? = nil

        required init() {
            
        }
    }
}
