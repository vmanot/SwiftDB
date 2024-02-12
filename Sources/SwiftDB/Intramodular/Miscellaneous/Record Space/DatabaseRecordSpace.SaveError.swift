//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import Swallow

public struct DatabaseRecordSpaceSaveError<Context: DatabaseRecordSpace>: CustomStringConvertible, LocalizedError {
    public let description: String
    public let mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    
    public var errorDescription: String? {
        description
    }
    
    public init(
        description: String,
        mergeConflicts: [DatabaseRecordMergeConflict<Context>]?
    ) {
        self.description = description
        self.mergeConflicts = mergeConflicts
    }
}
