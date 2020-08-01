//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swift

public protocol EntityPropertyDescription {
    var name: String { get }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    
    func toNSPropertyDescription() -> NSPropertyDescription
}
