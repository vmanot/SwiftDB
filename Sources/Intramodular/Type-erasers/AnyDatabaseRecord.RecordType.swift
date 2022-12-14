//
// Copyright (c) Vatsal Manot
//

import Swallow
import Merge

extension AnyDatabaseRecord {
    public struct RecordType {
        typealias RawValue = any Codable & Hashable & LosslessStringConvertible
        
        private let rawValue: RawValue
        
        public var description: String {
            rawValue.description
        }
        
        private init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public init(erasing value: any Codable & Hashable & LosslessStringConvertible) {
            self.init(rawValue: value)
        }
        
        public init(_ description: String) {
            self.rawValue = description
        }
        
        func _cast<T: LosslessStringConvertible>(to recordType: T.Type) throws -> T {
            try (try? cast(rawValue, to: recordType)) ?? (try T(description).unwrap())
        }
    }
}

// MARK: - Conformances -

extension AnyDatabaseRecord.RecordType: Codable {
    public init(from decoder: Decoder) throws {
        try self.init(from: String(from: decoder)) // FIXME: Should decoding be unavailable?
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension AnyDatabaseRecord.RecordType: Hashable {
    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.hashValue == rhs.rawValue.hashValue
    }
}

extension AnyDatabaseRecord.RecordType: LosslessStringConvertible {
    public init<T: LosslessStringConvertible>(from value: T) {
        self.rawValue = value.description
    }
}
