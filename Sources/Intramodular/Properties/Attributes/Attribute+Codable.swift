//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow
import SwiftUI

extension Attribute {
    public func encode(to encoder: Encoder) throws {
        if let wrappedValue = wrappedValue as? Codable {
           try wrappedValue.encode(to: encoder)
        } else if let wrappedValue = wrappedValue as? NSCoding {
            try wrappedValue.encode(to: encoder)
        } else {
            assertionFailure()
        }
    }
    
    public func decode(from decoder: Decoder) throws {
        if let valueType = Value.self as? Decodable.Type {
            initialValue = try cast(try valueType.init(from: decoder), to: Value.self)
        } else if let valueType = Value.self as? NSCoding.Type {
            initialValue = try cast(try valueType.decode(from: decoder), to: Value.self)
        } else {
            assertionFailure()
        }
    }
}

// MARK: - Auxiliary Implementation -

extension NSCoding {
    fileprivate static func decode(from decoder: Decoder) throws -> NSCoding {
        try NSKeyedArchived<Self>.init(from: decoder).wrappedValue
    }
    
    fileprivate func encode(to encoder: Encoder) throws {
        try NSKeyedArchived(wrappedValue: self).encode(to: encoder)
    }
}
