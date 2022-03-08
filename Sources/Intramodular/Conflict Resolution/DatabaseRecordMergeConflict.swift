//
// Copyright (c) Vatsal Manot
//

import Swift

/// An encapsulation of conflicts that occur during an attempt to save changes in a database record context.
public struct DatabaseRecordMergeConflict<Context: DatabaseRecordContext> {
    let source: Context.Record
}
