//
// Copyright (c) Vatsal Manot
//

import SwiftDB

extension _CoreDataTestSuite {
    struct TestSchema: Schema {
        var body: Body {
            FooEntity.self
        }
    }
    
    class FooEntity: CustomStringConvertible, Entity, Codable, ObservableObject {
        @Attribute var x: Int = 0
        
        var description: String {
            "Foo \(x)"
        }
        
        required init() {
            
        }
    }
}
