//
// Copyright (c) Vatsal Manot
//

import SwiftDB

extension _CoreDataTestSuite {
    struct TestSchema: Schema {
        var body: Body {
            TestEntity.self
        }
    }
    
    class TestEntity: CustomStringConvertible, Entity, Codable {
        @Attribute var foo: Int = 0
                
        required init() {
            
        }
    }
}
