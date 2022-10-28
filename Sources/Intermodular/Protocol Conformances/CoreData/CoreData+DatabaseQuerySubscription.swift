//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

extension _CoreData.Database {
    public final class QuerySubscription: DatabaseQuerySubscription {
        private let recordSpace: RecordSpace
        
        public var objectWillChange: ObservableObjectPublisher {
            recordSpace.objectWillChange
        }
        
        public init(recordSpace: RecordSpace) {
            self.recordSpace = recordSpace
        }
    }
}
