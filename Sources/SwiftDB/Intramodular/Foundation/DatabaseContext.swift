//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// A context that encapsulates the following:
/// - The active SwiftDB runtime.
/// - The active schema.
/// - The active schema adaptor.
public struct DatabaseContext<Database: SwiftDB.Database> {
    public let runtime: _SwiftDB_Runtime
    public let schema: _Schema
    public let schemaAdaptor: Database.SchemaAdaptor
    
    public init(
        runtime: _SwiftDB_Runtime,
        schema: _Schema,
        schemaAdaptor: Database.SchemaAdaptor
    ) {
        self.runtime = runtime
        self.schema = schema
        self.schemaAdaptor = schemaAdaptor
    }

    public func recordSchema(
        forRecordType recordType: Database.Record.RecordType
    ) throws -> _Schema.Record? {
        guard let recordSchemaID = try schemaAdaptor.entity(forRecordType: recordType) else {
            return nil
        }
        
        return schema[recordSchemaID]
    }
}

extension DatabaseContext {
    public func eraseToAnyDatabaseContext() -> DatabaseContext<AnyDatabase> {
        .init(
            runtime: runtime,
            schema: schema,
            schemaAdaptor: .init(erasing: schemaAdaptor)
        )
    }
}
