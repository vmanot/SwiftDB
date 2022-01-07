//
// Copyright (c) Vatsal Manot
//

import CoreData
import FoundationX
import Merge
import Swallow

public struct DatabaseRecordContextSaveError<Context: DatabaseRecordContext>: Error {
    public let mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    
    public init(
        mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    ) {
        self.mergeConflicts = mergeConflicts
    }
}
