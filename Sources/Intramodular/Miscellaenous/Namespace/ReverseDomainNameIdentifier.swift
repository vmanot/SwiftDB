//
// Copyright (c) Vatsal Manot
//

import Swallow
import Swift

///
/// An identifier in the reverse domain name notation form.
/// See more here - https://en.wikipedia.org/wiki/Reverse_domain_name_notation.
///
public struct ReverseDomainNameIdentifier: Codable, Hashable, Identifier {
    private let value: String
    
    public init(_ identifier: String) {
        self.value = identifier
    }
    
    public init(from decoder: Decoder) throws {
        self.init(try decoder.decode(single: String.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        try encoder.encode(single: value)
    }
}
