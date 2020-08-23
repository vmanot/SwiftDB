//
// Copyright (c) Vatsal Manot
//

import Swallow

/// Represents a namespace in a hierarchy-based system.
public struct HierarchicalNamespace: Codable, Hashable {
    public typealias Segment = HierarchicalNamespaceSegment
    
    public var segments: [Segment]
    
    public static var none: HierarchicalNamespace {
        .init([.none])
    }
    
    public init() {
        self.segments = []
    }
    
    public init(_ segment: Segment) {
        self.segments = [segment]
    }
    
    public func join(_ other: Self) -> Self {
        appending(contentsOf: other)
    }
}

// MARK: - Extensions -

extension HierarchicalNamespace {
    public var singleSegment: Segment? {
        guard count == 1 else {
            return nil
        }
        
        return self[0]
    }
    
    public var twoSegments: (Segment, Segment)? {
        guard count == 2 else {
            return nil
        }
        
        return (self[0], self[1])
    }
    
    public var isSingleNone: Bool {
        guard segments.count == 1 else {
            return false
        }
        
        return segments[0].isNone
    }
    
    public var isSingleSome: Bool {
        guard segments.count == 1 else {
            return false
        }
        
        return !segments[0].isNone
    }
}

// MARK: - Protocol Implementations -

extension HierarchicalNamespace: Collection {
    public var startIndex: Int {
        segments.startIndex
    }
    
    public var endIndex: Int {
        segments.endIndex
    }
    
    public subscript(_ index: Int) -> Segment {
        segments[index]
    }
}

extension HierarchicalNamespace: CustomStringConvertible {
    public var description: String {
        segments.map({ $0.description }).joined(separator: ".")
    }
}

extension HierarchicalNamespace: ExtensibleSequence {
    public typealias Element = Segment
    
    public mutating func insert(_ segment: Segment) {
        segments.insert(segment)
    }
    
    public mutating func append(_ segment: Segment) {
        segments.append(segment)
    }
    
    public func makeIterator() -> Array<Segment>.Iterator {
        segments.makeIterator()
    }
}

extension HierarchicalNamespace: SequenceInitiableSequence {
    public init<S: Sequence>(_ source: S) where S.Element == Element {
        segments = .init(source)
    }
}

extension HierarchicalNamespace: LosslessStringConvertible {
    public init(_ description: String) {
        segments = Segment(description).toArray()
    }
}
