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
            public enum ToOne {
                case set(Database.Record.ID?)
            }
            
            public enum ToMany {
                case insert(Database.Record.ID)
                case remove(Database.Record.ID)
                case set(Set<Database.Record.ID>)
            }
            
            public enum ToOrderedMany {
                case insert(Database.Record.ID)
                case remove(Database.Record.ID)
                case set([Database.Record.ID])
            }
            
            case toOne(ToOne)
            case toUnorderedMany(ToMany)
            case toOrderedMany(ToOrderedMany)
        }
        
        case data(Data)
        case relationship(Relationship)
    }
}

extension DatabaseRecordUpdate where Database == AnyDatabase {
    func _cast<T: SwiftDB.Database>(
        to type: DatabaseRecordUpdate<T>.Type
    ) throws -> DatabaseRecordUpdate<T> {
        .init(key: key, payload: try payload._cast(to: type.Payload.self))
    }
}

extension DatabaseRecordUpdate.Payload where Database == AnyDatabase {
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
                    case .toOne(let update):
                        switch update {
                            case .set(let recordID):
                                return .relationship(.toOne(.set(try recordID.map({ try $0._cast(to: T.Record.ID.self) }))))
                        }
                    case .toUnorderedMany(let update):
                        switch update {
                            case .insert(let recordID):
                                return .relationship(.toUnorderedMany(.insert(try recordID._cast(to: T.Record.ID.self))))
                            case .remove(let recordID):
                                return .relationship(.toUnorderedMany(.remove(try recordID._cast(to: T.Record.ID.self))))
                            case .set(let recordIDs):
                                return .relationship(
                                    .toUnorderedMany(
                                        .set(
                                            Set(try recordIDs.map({ try $0._cast(to: T.Record.ID.self) }))
                                        )
                                    )
                                )
                        }
                    case .toOrderedMany(let update):
                        switch update {
                            case .insert(let recordID):
                                return .relationship(.toOrderedMany(.insert(try recordID._cast(to: T.Record.ID.self))))
                            case .remove(let recordID):
                                return .relationship(.toOrderedMany(.remove(try recordID._cast(to: T.Record.ID.self))))
                            case .set(let recordIDs):
                                return .relationship(
                                    .toOrderedMany(
                                        .set(
                                            try recordIDs.map({ try $0._cast(to: T.Record.ID.self) })
                                        )
                                    )
                                )
                        }
                }
        }
    }
}
