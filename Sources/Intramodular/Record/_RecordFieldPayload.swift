//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public indirect enum _RecordFieldPayload: Codable, Hashable {
    public indirect enum _EntityAttributeValue: Codable, Hashable {
        case primitive(value: _PersistentTypeRepresentedCodable)
        case array(value: [_PersistentTypeRepresentedCodable])
        case dictionary(value: [_PersistentTypeRepresentedCodable: _PersistentTypeRepresentedCodable])
        case object(value: _PersistentTypeRepresentedCodable)
    }
    
    case attribute(value: _EntityAttributeValue)
    case relationship(primaryKeysOrRecordIdentifiers: _RelatedPrimaryKeysOrRecordIDs)
    
    public init(from value: Any) throws {
        if let value = value as? _RecordFieldPayloadConvertible {
            self = try value._toRecordFieldPayload()
        } else {
            self = .attribute(value: .object(value: _PersistentTypeRepresentedCodable(try cast(value, to: Codable.self))))
        }
    }
}

public enum _RelatedDatabaseRecords: Sequence {
    case toOne(AnyDatabaseRecord?)
    case toMany(Array<AnyDatabaseRecord>)
    case orderedToMany(Array<AnyDatabaseRecord>)
    
    public func makeIterator() -> Array<AnyDatabaseRecord>.Iterator {
        switch self {
            case .toOne(let record):
                return (record.map({ [$0] }) ?? []).makeIterator()
            case .toMany(let records):
                return records.makeIterator()
            case .orderedToMany(let records):
                return records.makeIterator()
        }
    }
}

public indirect enum _RelatedPrimaryKeysOrRecordIDs: Codable, Hashable {
    case toOne(keyOrIdentifier: _PrimaryKeyOrRecordID?)
    case toMany(keysOrIdentifiers: Set<_PrimaryKeyOrRecordID>)
    case orderedToMany(keysOrIdentifiers: [_PrimaryKeyOrRecordID])
}

public indirect enum _PrimaryKeyOrRecordID: Codable, Hashable {
    case primaryKey(value: _RecordFieldPayload)
    case recordID(value: _PersistentTypeRepresentedCodable)
}
