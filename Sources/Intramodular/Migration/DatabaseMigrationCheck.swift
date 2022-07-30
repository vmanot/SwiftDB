//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

public struct DatabaseMigrationCheck<Database: SwiftDB.Database> {
    public let zonesToMigrate: Set<Database.Zone.ID>
}
