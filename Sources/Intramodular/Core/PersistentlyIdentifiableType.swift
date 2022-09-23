//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol PersistentlyIdentifiableType {
    associatedtype PersistentTypeIdentifier: Codable & LosslessStringConvertible
    
    /// An identifier that uniquely identifies this type.
    static var persistentTypeIdentifier: PersistentTypeIdentifier { get }
}
