//
// Copyright (c) Vatsal Manot
//

import Swallow
import Task

public protocol Database: Named, Identifiable where ID: Codable {
    associatedtype ObjectContext: DatabaseObjectContext
    
    typealias Zone = ObjectContext.Zone
    
    func fetchAllZones() -> AnyTask<[Zone], Error>
    func fetchZone(named _: String) -> AnyTask<Zone, Error>
    
    func context(forZones _: [Zone]) -> ObjectContext
}
