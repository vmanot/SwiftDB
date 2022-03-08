//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

public struct DatabaseRecordContextSaveError<Context: DatabaseRecordContext>: Error {
    public let description: String
    public let mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    
    public init(
        description: String,
        mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    ) {
        self.description = description
        self.mergeConflicts = mergeConflicts
    }
}
