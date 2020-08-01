//
// Copyright (c) Vatsal Manot
//

import Data
import Swift

/// A shadow protocol for `Model`.
public protocol opaque_Model {
    static var opaque_PreviousVersion: opaque_Model.Type { get }
    static var opaque_NextVersion: opaque_Model.Type { get }
    
    static var version: Version? { get }
}

/// A type that represents a data model.
public protocol Model: opaque_Model {
    associatedtype PreviousVersion: Model = Never
    associatedtype NextVersion: Model = Never
    
    static var version: Version? { get }
    
    static func migrate(from _: PreviousVersion) throws -> Self
}

// MARK: - Implementation -

extension opaque_Model where Self: Model {
    public static var opaque_PreviousVersion: opaque_Model.Type {
        PreviousVersion.self
    }
    
    public static var opaque_NextVersion: opaque_Model.Type {
        NextVersion.self
    }
}

extension Model {
    static public var version: Version? {
        guard PreviousVersion.self == Never.self else {
            assertionFailure()
            
            return nil
        }
        
        return nil
    }
    
    public static func migrate(from _: PreviousVersion) throws -> Self {
        throw _DefaultMigrationError.unimplemented
    }
}

// MARK: - Auxiliary Implementation -

extension Never: Model {
    public static var version: Version? {
        nil
    }
}

public enum _DefaultMigrationError: Error {
    case unimplemented
}
