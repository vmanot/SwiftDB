//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

public protocol Database: Named, Identifiable where ID: Codable {
    associatedtype Configuration: Codable
    associatedtype State: Codable & ExpressibleByNilLiteral
    associatedtype RecordContext: DatabaseRecordContext
    associatedtype Zone where Zone == RecordContext.Zone
    
    var schema: SchemaDescription? { get }
    var configuration: Configuration { get }
    var state: State { get }
    var capabilities: [DatabaseCapability] { get }
    
    init(schema: SchemaDescription?, configuration: Configuration, state: State) throws
    
    func fetchAllZones() -> AnyTask<[Zone], Error>
    func fetchZone(named _: String) -> AnyTask<Zone, Error>
    
    func recordContext(forZones _: [Zone]) -> RecordContext
}
