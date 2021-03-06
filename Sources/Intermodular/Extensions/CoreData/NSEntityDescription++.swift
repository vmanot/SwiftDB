//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

extension NSEntityDescription {
    public var allKeys: [CodingKey] {
        properties.map({ AnyStringKey(stringValue: $0.name) }) + (superentity?.allKeys ?? [])
    }
    
    public func contains<Key: CodingKey>(key: Key) -> Bool {
        allKeys.contains(where: { $0.stringValue == key.stringValue })
    }
}
