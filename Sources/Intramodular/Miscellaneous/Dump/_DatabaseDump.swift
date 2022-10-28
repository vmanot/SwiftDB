//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow
import SwiftUIX

public struct _DatabaseDump: Codable, Hashable {
    public var records: [_DatabaseRecordDump]
}

extension DatabaseCRUDQ {
    public func _dumpDatabase() async throws -> _DatabaseDump {
        let instances = try await fetchAllInstances()
        
        var recordDumps: [_DatabaseRecordDump] = []
        
        for instance in instances {
            let entity = try cast(instance, to: (any Entity).self)
            let recordContainer = try entity._underlyingDatabaseRecordContainer.unwrap()
            
            try recordDumps.append(recordContainer._dumpRecord())
        }
        
        return .init(records: recordDumps)
    }
}
