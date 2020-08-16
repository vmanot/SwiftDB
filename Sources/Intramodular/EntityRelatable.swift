//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public protocol _opaque_EntityRelatable {
    
}

public protocol EntityRelatable: _opaque_EntityRelatable {
    
}

extension EntityRelatable {
    public static func from(base: NSManagedObject, key: AnyStringKey) throws -> Self {
        fatalError()
    }
}

// MARK: - Implementation -

extension Optional: _opaque_EntityRelatable where Wrapped: _opaque_EntityRelatable {
    
}

extension Optional: EntityRelatable where Wrapped: EntityRelatable {
    
}
