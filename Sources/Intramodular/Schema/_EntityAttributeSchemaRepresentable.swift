//
// Copyright (c) Vatsal Manot
//

import Swift

protocol _EntityAttributeSchemaRepresentable {
    static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType
}

// MARK: - Conformances

extension Bool: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .boolean)
    }
}

extension Character: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .string)
    }
}

extension Date: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .date)
    }
}

extension Data: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .binaryData)
    }
}

extension Decimal: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .decimal)
    }
}

extension Double: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .double)
    }
}

extension Float: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .float)
    }
}

extension Int: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .integer64)
    }
}

extension Int16: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .integer16)
    }
}

extension Int32: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .integer32)
    }
}

extension Int64: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .integer64)
    }
}

extension String: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .string)
    }
}

extension URL: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .URI)
    }
}

extension UUID: _EntityAttributeSchemaRepresentable {
    public static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .primitive(type: .UUID)
    }
}

extension Array: _EntityAttributeSchemaRepresentable {
    static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .array(elementType: .init(from: Element.self))
    }
}

extension Dictionary: _EntityAttributeSchemaRepresentable {
    static func toSchemaEntityAttributeType() -> _Schema.Entity.AttributeType {
        .dictionary(keyType: .init(from: Key.self), valueType: .init(from: Value.self))
    }
}
