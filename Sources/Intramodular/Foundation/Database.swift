//
// Copyright (c) Vatsal Manot
//

import Swallow
import Task

public protocol Database: Named, Identifiable where ID: Codable {
    associatedtype Configuration: Codable
    associatedtype State: Codable & ExpressibleByNilLiteral
    associatedtype RecordContext: DatabaseRecordContext
    
    typealias Zone = RecordContext.Zone
    
    var configuration: Configuration { get }
    var state: State { get }
    var capabilities: [DatabaseCapability] { get }
    
    init(configuration: Configuration, state: State) throws
    
    func fetchAllZones() -> AnyTask<[Zone], Error>
    func fetchZone(named _: String) -> AnyTask<Zone, Error>
    
    func recordContext(forZones _: [Zone]) -> RecordContext
}
