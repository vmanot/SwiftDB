//
// Copyright (c) Vatsal Manot
//

import CoreData
import Foundation
import Swift

public final class EntityRelationshipDescription: EntityPropertyDescription {
    public enum CodingKeys: String, CodingKey {
        case destination
        case inverse
        case minCount
        case maxCount
        case deleteRule
    }
    
    let destination: EntityDescription?
    let inverse: EntityRelationshipDescription?
    let minCount: Int
    let maxCount: Int?
    let deleteRule: NSDeleteRule
    
    public init(
        name: String,
        isOptional: Bool,
        isTransient: Bool,
        destination: EntityDescription?,
        inverse: EntityRelationshipDescription?,
        minCount: Int,
        maxCount: Int?,
        deleteRule: NSDeleteRule
    ) {
        self.destination = destination
        self.inverse = inverse
        self.minCount = minCount
        self.maxCount = maxCount
        self.deleteRule = deleteRule
        
        super.init(name: name, isOptional: isOptional, isTransient: isTransient)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
        
        // try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        fatalError()
    }
    
    public override func toNSPropertyDescription() -> NSPropertyDescription {
        fatalError()
    }
}

// MARK: - Auxiliary Implementation -

extension NSRelationshipDescription {
    public convenience init(_ description: EntityRelationshipDescription) {
        self.init()
        
        name = description.name
        isOptional = description.isOptional
        isTransient = description.isTransient
        
        destinationEntity = description.destination.map(NSEntityDescription.init)
        inverseRelationship = description.inverse.map(NSRelationshipDescription.init)
        minCount = description.minCount
        maxCount = description.maxCount ?? 0
        deleteRule = description.deleteRule
    }
}
