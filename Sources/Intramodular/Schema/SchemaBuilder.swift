//
// Copyright (c) Vatsal Manot
//

import Swallow
import Swift

@resultBuilder
public final class SchemaBuilder {
    public typealias Element = _opaque_Entity.Type
    
    public static func buildBlock() -> [Element] {
        []
    }
    
    public static func buildBlock(_ element: Element) -> [Element] {
        [element]
    }
    
    public static func buildBlock(_ elements: Element...) -> [Element] {
        elements
    }
    
    public static func buildBlock(_ elements: [Element]) -> [Element] {
        elements
    }
}
