//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol PrimitiveAttributeDataType {
    
}

// MARK: - Conditional Conformances -

extension Optional: PrimitiveAttributeDataType where Wrapped: PrimitiveAttributeDataType {
    
}

extension RawRepresentable where RawValue: PrimitiveAttributeDataType {
    
}

// MARK: - Conformances -

extension Bool: PrimitiveAttributeDataType {
    
}

extension Character: PrimitiveAttributeDataType {
    
}

extension Date: PrimitiveAttributeDataType {
    
}

extension Data: PrimitiveAttributeDataType {
    
}

extension Decimal: PrimitiveAttributeDataType {
    
}

extension Double: PrimitiveAttributeDataType {
    
}

extension Float: PrimitiveAttributeDataType {
    
}

extension Int: PrimitiveAttributeDataType {
    
}

extension Int16: PrimitiveAttributeDataType {
    
}

extension Int32: PrimitiveAttributeDataType {
    
}

extension Int64: PrimitiveAttributeDataType {
    
}

extension String: PrimitiveAttributeDataType {
    
}

extension URL: PrimitiveAttributeDataType {
    
}

extension UUID: PrimitiveAttributeDataType {
    
}
