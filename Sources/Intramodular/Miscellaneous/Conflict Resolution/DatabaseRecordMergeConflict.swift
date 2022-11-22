//
// Copyright (c) Vatsal Manot
//

import Swift

/// An encapsulation of conflicts that occur during an attempt to save changes in a database record space.
public struct DatabaseRecordMergeConflict<Context: DatabaseRecordSpace> {
    let source: Context.Record
}
