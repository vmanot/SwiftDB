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
    associatedtype PreviousVersion: EnclosedEvolutionModel
    
    static var version: Version? { get }
    
    func migrate(from previous: PreviousVersion) -> Self
}

extension Never: EnclosedEvolutionModel {
    public typealias PreviousVersion = Never
    
    public static var version: Version? {
        nil
    }

    public func migrate(from _: Never) -> Never {
        
    }
}
