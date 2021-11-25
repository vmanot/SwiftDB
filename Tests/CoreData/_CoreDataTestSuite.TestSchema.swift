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
    
    class TestEntity: Entity, Codable {
        @Attribute var foo: Int = 0
                
        required init() {
            
        }
    }
}
