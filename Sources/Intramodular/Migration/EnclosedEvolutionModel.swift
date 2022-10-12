//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Swallow

/// A model that has enclosed evolution.
///
/// The migration of this model is independent relative to its enclosing scope.
/// Put simply, this model is capable of migration without needing access to anything but the older version of the model.
public protocol EnclosedEvolutionModel: Model {
    static var version: Version? { get }
}

/// An enclosed evolution model that establishes a migration step between a previous version of its model and itself.
public protocol EnclosedEvolutionMigratableModel: EnclosedEvolutionModel {
    associatedtype PreviousVersion: EnclosedEvolutionModel
    
    static func migrate(from previous: PreviousVersion) -> Self
}

/// An enclosed evolution entity that establishes a migration step between a previous version of its model and itself.
public protocol EnclosedEvolutionMigratableEntity {
    associatedtype PreviousVersion: EnclosedEvolutionModel
    
    func migrate(from previous: PreviousVersion)
}
