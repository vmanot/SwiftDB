//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swallow

/// A database zone.
///
/// This is a flexible concept that spans across RDBMSs to document-oriented databases.
public protocol DatabaseZone: Named, Identifiable where ID: Codable {
    
}
