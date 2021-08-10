//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public protocol Database: Named, Identifiable where ID: Codable {
    typealias Runtime = DatabaseRuntime
    typealias Schema = DatabaseSchema
    
    associatedtype Configuration: Codable
    associatedtype State: Codable & ExpressibleByNilLiteral
    associatedtype RecordContext: DatabaseRecordContext
    associatedtype Zone where Zone == RecordContext.Zone
    
    var schema: DatabaseSchema? { get }
    var configuration: Configuration { get }
    var state: State { get }
    var capabilities: [DatabaseCapability] { get }
    
    init(
        runtime: Runtime,
        schema: Schema?,
        configuration: Configuration,
        state: State
    ) throws
    
    @discardableResult
    func fetchAllAvailableZones() -> AnyTask<[Zone], Error>
    @discardableResult
    func fetchZone(named _: String) -> AnyTask<Zone, Error>
    
    func recordContext(forZones _: [Zone]?) throws -> RecordContext
    
    func delete() -> AnyTask<Void, Error>
}

// MARK: - Extensions -

extension Database {
    public init(
        schema: Schema?,
        configuration: Configuration,
        state: State
    ) throws {
        try self.init(
            runtime: _DefaultDatabaseRuntime(),
            schema: schema,
            configuration: configuration,
            state: state
        )
    }
}
