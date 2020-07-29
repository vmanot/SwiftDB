//
// Copyright (c) Vatsal Manot
//

import Data
import Swift

public protocol opaque_DataModel {
    static var opaque_PreviousVersion: opaque_DataModel.Type { get }
    static var opaque_NextVersion: opaque_DataModel.Type { get }
}

/// A type that represents a data model.
public protocol DataModel: opaque_DataModel {
    associatedtype PreviousVersion: DataModel = Never
    associatedtype NextVersion: DataModel = Never
    
    static var version: Version? { get }
    
    static func migrate(from _: PreviousVersion) throws -> Self
}

// MARK: - Implementation -

extension opaque_DataModel where Self: DataModel {
    public static var opaque_PreviousVersion: opaque_DataModel.Type {
        PreviousVersion.self
    }
    
    public static var opaque_NextVersion: opaque_DataModel.Type {
        NextVersion.self
    }
}

extension DataModel {
    public static func migrate(from _: PreviousVersion) throws -> Self {
        throw _DefaultMigrationError.unimplemented
    }
}

// MARK: - Auxiliary Implementation -

extension Never: DataModel {
    public static var version: Version? {
        nil
    }
}

public enum _DefaultMigrationError: Error {
    case unimplemented
}
