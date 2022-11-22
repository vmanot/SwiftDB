//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

// MARK: - Auxiliary -

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var _SwiftDB_DatabaseContainer: AnyDatabaseContainer! {
        get {
            self[._SwiftDB_DatabaseContainer] as? AnyDatabaseContainer
        } set {
            self[._SwiftDB_DatabaseContainer] = newValue
        }
    }
}

extension CodingUserInfoKey {
    fileprivate static let _SwiftDB_DatabaseContainer = CodingUserInfoKey(rawValue: "_SwiftDB_DatabaseContainer")!
}
