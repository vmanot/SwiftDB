//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

extension DatabaseContainer {
    public convenience init(name: String, schema: Schema) throws {
        try self.init(
            name: name,
            schema: schema,
            location: nil
        )
    }
    
    public convenience init(
        name: String,
        schema: Schema,
        location: CanonicalFileDirectory,
        sqliteFilePath: String
    ) throws {
        try self.init(
            name: name,
            schema: schema,
            location: location.toURL().appendingPathComponent(sqliteFilePath)
        )
    }
}
