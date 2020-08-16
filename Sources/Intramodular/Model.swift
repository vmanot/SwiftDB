//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A shadow protocol for `Model`.
public protocol _opaque_Model {
    static var _opaque_PreviousVersion: _opaque_Model.Type { get }
    static var _opaque_NextVersion: _opaque_Model.Type { get }
    
    static var version: Version? { get }
}

/// A type that represents a data model.
public protocol Model: _opaque_Model {
    associatedtype PreviousVersion: Model = Never
    associatedtype NextVersion: Model = Never
    
    static var version: Version? { get }
    
    static func migrate(from _: PreviousVersion) throws -> Self
}

// MARK: - Implementation -

extension _opaque_Model where Self: Model {
    public static var _opaque_PreviousVersion: _opaque_Model.Type {
        PreviousVersion.self
    }
    
    public static var _opaque_NextVersion: _opaque_Model.Type {
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
