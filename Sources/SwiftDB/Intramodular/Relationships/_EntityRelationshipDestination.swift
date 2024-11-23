//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow
import Swift

public protocol _EntityRelationshipDestination {
    static var _destinationEntityType: any Entity.Type { get }
    
    init(_relationshipPropertyAccessor: EntityPropertyAccessor) throws
}

public protocol _EntityRelationshipToOneDestination: _EntityRelationshipDestination {
    associatedtype _DestinationEntityType: Entity
}

public protocol _EntityRelationshipToManyDestination: _EntityRelationshipDestination {
    associatedtype _DestinationEntityType: Entity
}

// MARK: - Implementation

extension _EntityRelationshipDestination {
    public static var _destinationEntityType: any Entity.Type {
        if let type = self as? any _EntityRelationshipToOneDestination.Type {
            return type._toOneDestinationEntityType
        } else if let type = self as? any _EntityRelationshipToManyDestination.Type {
            return type._toManyDestinationEntityType
        } else {
            fatalError()
        }
    }
}

// MARK: - Extensions

extension _EntityRelationshipToOneDestination {
    fileprivate static var _toOneDestinationEntityType: any Entity.Type {
        _DestinationEntityType.self
    }
}

extension _EntityRelationshipToManyDestination {
    fileprivate static var _toManyDestinationEntityType: any Entity.Type {
        _DestinationEntityType.self
    }
}

// MARK: - Conformees

extension Optional: _EntityRelationshipDestination  {
    public init(_relationshipPropertyAccessor: EntityPropertyAccessor) {
        self = nil
    }
}

extension Optional: _EntityRelationshipToOneDestination where Wrapped: Entity {
    public typealias _DestinationEntityType = Wrapped
}

extension Optional: _EntityRelationshipToManyDestination where Wrapped: _EntityRelationshipToManyDestination {
    public typealias _DestinationEntityType = Wrapped._DestinationEntityType
}
