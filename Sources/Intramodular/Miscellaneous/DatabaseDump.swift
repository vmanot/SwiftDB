//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Swift
import SwiftUIX

public struct DatabaseDump: Codable {
    public var zonedRecords: [AnyDatabase.Zone.ID]
}

public struct AnyDatabaseRecordDump {
    public let fields: [AnyStringKey: AnyCodable]
    public let relationshipIDs: [AnyStringKey: AnyCodable]
}
