//
// Copyright (c) Vatsal Manot
//

import XCTest

#if !canImport(ObjectiveC)

public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftDBTests.allTests),
    ]
}

#endif
