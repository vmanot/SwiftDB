//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow
import SwiftUI

/// An encapsulation of a request to dereference a relationship from stemming from a database record.
public struct DatabaseRecordRelationshipDereferenceRequest<RecordID: Hashable>: Hashable {
    public let recordID: RecordID
    public let key: AnyStringKey
}
