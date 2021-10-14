//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A shadow protocol for `Model`.
public protocol _opaque_Model {
    static var version: Version? { get }
}

/// A type that represents a data model.
public protocol Model: _opaque_Model {
    static var version: Version? { get }
}

// MARK: - Implementation -

extension _opaque_Model {
    static public var version: Version? {
        return nil
    }
}

// MARK: - Auxiliary Implementation -

extension Never: Model {
    public static var version: Version? {
        nil
    }
}
