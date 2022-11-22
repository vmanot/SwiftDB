//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// A type-erased database container.
///
/// Use this type to propagate a reference to your database container in your SwiftUI hierarchy.
public class AnyDatabaseContainer: CustomReflectable, Loggable, ObservableObject, @unchecked Sendable {
    public enum Status: String, CustomStringConvertible {
        case uninitialized
        case initializing
        case initialized
        case deinitializing
        case migrationCheckFailed
        case migrationRequired
        
        public var description: String {
            rawValue
        }
    }
    
    public private(set) var liveAccess = LiveAccess()
    
    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
    
    @Published internal(set) public var status: Status = .uninitialized
    
    public func load() async throws {
        fatalError(reason: .abstract)
    }
    
    public func transact<R>(
        _ body: @escaping (AnyLocalTransaction) throws -> R
    ) async throws -> R {
        fatalError(reason: .abstract)
    }
    
    public func reset() async throws {
        fatalError(reason: .abstract)
    }
}
