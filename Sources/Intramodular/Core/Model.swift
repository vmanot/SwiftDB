//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A type that represents a data model.
public protocol Model {
    static var version: Version? { get }
}

// MARK: - Implementation -

extension Model {
    static public var version: Version? {
        return nil
    }
}
