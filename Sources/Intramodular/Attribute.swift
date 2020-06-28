//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

public enum AttributeProperty {
    case transient
    case optional
}

@_functionBuilder
public class AttributePropertiesBuilder {
    @inlinable
    public static func buildBlock(_ element: AttributeProperty) -> [AttributeProperty] {
        return [element]
    }
    
    @inlinable
    public static func buildBlock(_ elements: AttributeProperty...) -> [AttributeProperty] {
        return elements
    }
}

@propertyWrapper
struct Attribute<Value> {
    var wrappedValue: Value {
        fatalError()
    }
    
    init(@AttributePropertiesBuilder _ action: () -> [AttributeProperty]) {
        
    }
}
