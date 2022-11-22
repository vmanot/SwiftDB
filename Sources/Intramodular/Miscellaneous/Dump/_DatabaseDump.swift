//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow
import SwiftUIX

public struct _DatabaseDump: Codable, Hashable {
    public var records: [_DatabaseRecordDump]
}

extension AnyLocalTransaction {
    public func _dumpDatabase() throws -> _DatabaseDump {
        let instances = try fetchAllInstances()
        
        var recordDumps: [_DatabaseRecordDump] = []
        
        for instance in instances {
            let entity = try cast(instance, to: (any Entity).self)
            let recordContainer = try entity._databaseRecordProxy.unwrap()
            
            try recordDumps.append(recordContainer._dumpRecord())
        }
        
        return .init(records: recordDumps)
    }
}
