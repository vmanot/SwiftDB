//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A model that has enclosed evolution.
///
/// The migration of this model is independent relative to its enclosing scope.
/// Put simply, this model is capable of migration without needing access to anything but the older version of the model.
public protocol EnclosedEvolutionModel: Model {
    
}
