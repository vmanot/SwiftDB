//
// Copyright (c) Vatsal Manot
//

import Data
import Runtime
import Swallow

public protocol Schema {
    typealias Entities = [opaque_Entity.Type]
    
    @ArrayBuilder<opaque_Entity.Type>
    var entities: Entities { get }
}

