//
// Copyright (c) Vatsal Manot
//

import API
import Merge
import Task

open class DatabaseFetchController: MutexProtected {
    public var mutex = OSUnfairLock()
    
    @MutexProtectedValue var currentCursor: PaginationCursor? = nil
    @MutexProtectedValue var limit: PaginationLimit = nil
    
    public init(
        initialCursor: PaginationCursor?,
        limit: PaginationLimit
    ) {
        $currentCursor.unsafelyAccessedValue = initialCursor
        $limit.unsafelyAccessedValue = limit
    }
    
    func fetch() throws -> Future<Bool, Error> {
        throw Never.Reason.abstract
    }
}
