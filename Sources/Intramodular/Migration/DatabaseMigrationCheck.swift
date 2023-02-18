//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

/// A type that encapsulates the assessment of a database to check whether any of its zones require a migration.
public struct DatabaseMigrationCheck<Database: SwiftDB.Database>: Sendable {
    public let zonesToMigrate: Set<Database.Zone.ID>
}
