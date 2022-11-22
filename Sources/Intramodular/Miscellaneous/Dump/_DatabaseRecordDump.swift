//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public struct _DatabaseRecordDump: Codable, Hashable, Identifiable {
    public typealias ID = _PrimaryKeyOrRecordID
    
    public let id: ID
    public let fields: [String: _RecordFieldPayload?]
}

extension _DatabaseRecordProxy {
    public func _dumpRecord() throws -> _DatabaseRecordDump {
        .init(
            id: try primaryKeyOrRecordID(),
            fields: try Dictionary(uniqueKeysWithValues: allKeys.map({ key in
                try (key.stringValue, decodeFieldPayload(forKey: key))
            }))
        )
    }
}
