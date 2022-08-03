//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// A type that represents a database.
///
/// A SwiftDB database has three main parts:
/// - Schema (if available)
/// - Configuration
/// - State
public protocol Database: Named, Identifiable where ID: Codable {
    typealias Runtime = _SwiftDB_Runtime
    
    associatedtype Configuration: Codable
    associatedtype State: Codable & Equatable
    associatedtype RecordContext: DatabaseRecordContext
    associatedtype Zone where Zone == RecordContext.Zone
    
    var configuration: Configuration { get }
    var state: State { get }
    var capabilities: [DatabaseCapability] { get }
    
    init(
        runtime: _SwiftDB_Runtime,
        schema: DatabaseSchema?,
        configuration: Configuration,
        state: State?
    ) throws
    
    @discardableResult
    func fetchAllAvailableZones() -> AnyTask<[Zone], Error>
    @discardableResult
    func fetchZone(named _: String) -> AnyTask<Zone, Error>
    
    func recordContext(forZones _: [Zone]?) throws -> RecordContext
    
    /// Erase all data in the database.
    ///
    /// This operation is always an atomic operation.
    func delete() -> AnyTask<Void, Error>
}

// MARK: - Extensions -

extension Database {
    public init(
        schema: DatabaseSchema?,
        configuration: Configuration,
        state: State?
    ) throws {
        try self.init(
            runtime: _Default_SwiftDB_Runtime(schema: schema),
            schema: schema,
            configuration: configuration,
            state: state
        )
    }
}
