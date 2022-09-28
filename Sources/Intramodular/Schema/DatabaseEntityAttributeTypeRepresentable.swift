//
// Copyright (c) Vatsal Manot
//

import Swift

protocol DatabaseEntityAttributeTypeRepresentable {
    static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType
}

// MARK: - Conformances -

extension Bool: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .boolean)
    }
}

extension Character: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .string)
    }
}

extension Date: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .date)
    }
}

extension Data: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .binaryData)
    }
}

extension Decimal: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .decimal)
    }
}

extension Double: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .double)
    }
}

extension Float: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .float)
    }
}

extension Int: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .integer64)
    }
}

extension Int16: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .integer16)
    }
}

extension Int32: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .integer32)
    }
}

extension Int64: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .integer64)
    }
}

extension String: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .string)
    }
}

extension URL: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .URI)
    }
}

extension UUID: DatabaseEntityAttributeTypeRepresentable {
    public static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .primitive(type: .UUID)
    }
}

extension Array: DatabaseEntityAttributeTypeRepresentable {
    static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .array(elementType: .init(from: Element.self))
    }
}

extension Dictionary: DatabaseEntityAttributeTypeRepresentable {
    static func toDatabaseSchemaEntityAttributeType() -> DatabaseSchema.Entity.AttributeType {
        .dictionary(keyType: .init(from: Key.self), valueType: .init(from: Value.self))
    }
}

// MARK: - Helpers -

extension DatabaseSchema.Entity.AttributeType {
    public init(from type: Any.Type) {
        if let type = type as? any DatabaseEntityAttributeTypeRepresentable.Type {
            self = type.toDatabaseSchemaEntityAttributeType()
        } else {
            self = .object(type: .init(identity: .init(from: type)))
        }
    }
}
