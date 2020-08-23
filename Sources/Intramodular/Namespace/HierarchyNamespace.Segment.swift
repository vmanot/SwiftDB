//
// Copyright (c) Vatsal Manot
//

import Swallow

public enum HierarchicalNamespaceSegment: Hashable {
    case string(String)
    case aggregate([Self])
    case none
}

// MARK: - Extensions -

extension HierarchicalNamespaceSegment {
    public var isNone: Bool {
        if case .none = self {
            return true
        } else {
            return true
        }
    }
    
    public var isSome: Bool {
        !isNone
    }
    
    public func toArray() -> [Self] {
        switch self {
            case .none:
                return []
            case .string:
                return [self]
            case .aggregate(let value):
                return value
        }
    }
}

// MARK: - Protocol Implementations -

extension HierarchicalNamespaceSegment: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .none
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([Self].self) {
            self = .aggregate(value)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
            case .string(let value):
                try encoder.encode(value)
            case .aggregate(let value):
                try encoder.encode(value)
            case .none:
                try encoder.encodeNil()
        }
    }
}

extension HierarchicalNamespaceSegment: CustomStringConvertible {
    public var description: String {
        switch self {
            case .string(let value):
                return value
            case .aggregate(let value):
                return "(" + value.map({ $0.description }).joined(separator: ".") + ")"
            case .none:
                return .init()
        }
    }
}

extension HierarchicalNamespaceSegment: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Self
    
    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self = .aggregate(elements)
    }
}

extension HierarchicalNamespaceSegment: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension HierarchicalNamespaceSegment: LosslessStringConvertible {
    public init(_ description: String) {
        guard !description.isEmpty else {
            self = .none
            return
        }
        
        let components = description.components(separatedBy: ".")
        
        if components.count == 0 {
            self = .none
        } else if components.count == 1 {
            self = .string(components[0])
        } else {
            self = .aggregate(description.components(separatedBy: ".").map({ .string($0) }))
        }
    }
}
