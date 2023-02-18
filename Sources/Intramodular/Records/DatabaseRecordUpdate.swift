//
// Copyright (c) Vatsal Manot
//

import Swift

public struct DatabaseRecordUpdate<Database: SwiftDB.Database> {
    public let key: AnyCodingKey
    public let payload: Payload
}

extension DatabaseRecordUpdate {
    public enum Payload {
        public enum Data {
            case setValue(Any)
            case removeValue
            
            var value: Any? {
                switch self {
                    case .setValue(let value):
                        return value
                    case .removeValue:
                        return nil
                }
            }
        }
        
        public enum Relationship {
            case set(RelatedDatabaseRecordIdentifiers<Database>)
            case apply(difference: RelatedDatabaseRecordIdentifiers<Database>.Difference)
        }
        
        case data(Data)
        case relationship(Relationship)
    }
}

// MARK: - Auxiliary

extension DatabaseRecordUpdate where Database == AnyDatabase {
    func _cast<T: SwiftDB.Database>(
        to type: DatabaseRecordUpdate<T>.Type
    ) throws -> DatabaseRecordUpdate<T> {
        .init(key: key, payload: try payload._cast(to: type.Payload.self))
    }
}

extension DatabaseRecordUpdate.Payload: _AnyDatabaseRuntimeCasting where Database == AnyDatabase {
    func _cast<T: SwiftDB.Database>(
        to type: DatabaseRecordUpdate<T>.Payload.Type
    ) throws -> DatabaseRecordUpdate<T>.Payload {
        switch self {
            case .data(let update):
                switch update {
                    case .setValue(let value):
                        return .data(.setValue(value))
                    case .removeValue:
                        return .data(.removeValue)
                }
            case .relationship(let update):
                switch update {
                    case .set(let value):
                        return .relationship(
                            .set(
                                try value._cast(to: RelatedDatabaseRecordIdentifiers<T>.self)
                            )
                        )
                    case .apply(let value):
                        return .relationship(
                            .apply(
                                difference: try value._cast(to: RelatedDatabaseRecordIdentifiers<T>.Difference.self)
                            )
                        )
                }
        }
    }
}
