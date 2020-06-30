//
// Copyright (c) Vatsal Manot
//

import Data
import Swift

/// A type that represents a data model.
public protocol DataModel {
    associatedtype PreviousVersion: DataModel = Never
    associatedtype NextVersion: DataModel = Never
    
    static var version: Version? { get }
}

// MARK: - Auxiliary Implementation -

extension Never: DataModel {
    public static var version: Version? {
        nil
    }
}
