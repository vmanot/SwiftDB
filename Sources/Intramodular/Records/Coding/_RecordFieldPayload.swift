//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public indirect enum _RecordFieldPayload: Codable, Hashable {
    case attribute(value: EntityAttributeValue)
    case relationship(primaryKeysOrRecordIdentifiers: RelatedPrimaryKeysOrRecordIDs)
    
    public init(from value: Any) throws {
        if let value = value as? _RecordFieldPayloadConvertible {
            self = try value._toRecordFieldPayload()
        } else {
            self = .attribute(
                value: .object(
                    value: _TypeSerializingAnyCodable(try cast(value, to: Codable.self))
                )
            )
        }
    }
}

extension _RecordFieldPayload {
    public enum EntityAttributeValue: Codable, Hashable {
        case primitive(value: _TypeSerializingAnyCodable)
        case array(value: [_TypeSerializingAnyCodable])
        case dictionary(value: [_TypeSerializingAnyCodable: _TypeSerializingAnyCodable])
        case object(value: _TypeSerializingAnyCodable)
    }
    
    public enum PrimaryKeyOrRecordID: Codable, Hashable {
        case primaryKey(value: _RecordFieldPayload)
        case recordID(value: _TypeSerializingAnyCodable)
        
        init(from recordID: AnyDatabaseRecord.ID) throws {
            self = .recordID(value: _TypeSerializingAnyCodable(try cast(recordID, to: Codable.self)))
        }
    }
    
    public enum RelatedPrimaryKeysOrRecordIDs: Codable, Hashable {
        case toOne(keyOrIdentifier: PrimaryKeyOrRecordID?)
        case toUnorderedMany(keysOrIdentifiers: Set<PrimaryKeyOrRecordID>)
        case toOrderedMany(keysOrIdentifiers: [PrimaryKeyOrRecordID])
    }
}
