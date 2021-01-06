//
// Copyright (c) Vatsal Manot
//

import Swift

public struct DatabaseRecordMergeConflict<Context: DatabaseRecordContext> {
    let source: Context.Record
}
