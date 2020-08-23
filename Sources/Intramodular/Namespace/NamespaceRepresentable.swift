//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol HierarchicalNamespaceRepresentable: AnyProtocol {
    init?(namespace: HierarchicalNamespace)
    init?(namespaceSegment: HierarchicalNamespace.Segment)

    func toNamespace() -> HierarchicalNamespace
}

public protocol NamespaceSegmentRepresentable: HierarchicalNamespaceRepresentable {
    init?(namespaceSegment: HierarchicalNamespace.Segment)

    func toNamespaceSegment() -> HierarchicalNamespace.Segment
}

// MARK: - Implementation -

extension HierarchicalNamespaceRepresentable {
    public init?(namespaceSegment: HierarchicalNamespace.Segment) {
        self.init(namespace: .init(namespaceSegment))
    }
}

extension NamespaceSegmentRepresentable {
    public init?(namespace: HierarchicalNamespace) {
        guard let segment = namespace.singleSegment else {
            return nil
        }

        self.init(namespaceSegment: segment)
    }

    public func toNamespace() -> HierarchicalNamespace {
        return .init(toNamespaceSegment())
    }
}

// MARK: - Concrete Implementations -

extension AnyStringIdentifier: NamespaceSegmentRepresentable {
    public init?(namespaceSegment: HierarchicalNamespace.Segment) {
        guard case let .string(value) = namespaceSegment else {
            return nil
        }

        self.init(value)
    }

    public func toNamespaceSegment() -> HierarchicalNamespace.Segment {
        return .string(value)
    }
}
