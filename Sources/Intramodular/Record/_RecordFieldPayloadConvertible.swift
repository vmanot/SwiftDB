//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public protocol _RecordFieldPayloadConvertible {
    func _toRecordFieldPayload() throws -> _RecordFieldPayload
}

extension Bool: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Character: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Date: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Data: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Decimal: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Double: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Float: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Int: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Int16: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Int32: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Int64: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension String: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension URL: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension UUID: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() -> _RecordFieldPayload {
        .attribute(value: .primitive(value: .init(self)))
    }
}

extension Array: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() throws -> _RecordFieldPayload {
        try .attribute(value: .array(value: self.map({ try _TypePersistingAnyCodable(cast($0, to: Codable.self)) })))
    }
}

extension Dictionary: _RecordFieldPayloadConvertible {
    public func _toRecordFieldPayload() throws -> _RecordFieldPayload {
        try .attribute(
            value: .dictionary(
                value: self
                    .mapKeys({ try _TypePersistingAnyCodable(cast($0, to: Codable.self)) })
                    .mapValues({ try _TypePersistingAnyCodable(cast($0, to: Codable.self)) })
            )
        )
    }
}
