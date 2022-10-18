//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

extension _CoreData.Database {
    public final class QuerySubscription: DatabaseQuerySubscription {
        private let recordContext: RecordContext
        
        public var objectWillChange: ObservableObjectPublisher {
            recordContext.objectWillChange
        }
        
        public init(recordContext: RecordContext) {
            self.recordContext = recordContext
        }
    }
}
