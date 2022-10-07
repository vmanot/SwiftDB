//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow
import SwiftUI

extension EntityRelationship {
    /*private var modelIDs: [AnyEncodable] {
        /*guard let id = (Value.RelatableEntityType.self as? any Identifiable.Type)?._opaque_ID else {
            assertionFailure()
            
            return []
        }
        
        guard id is Codable.Type else {
            return []
        }
        
        return try! wrappedValue.exportRelatableModels().map({ .init($0._opaque_id!.base as! Codable) })*/
    }*/
    
    public func encode(to encoder: Encoder) throws {

    }
    
    public func decode(from decoder: Decoder) throws {
        /*guard let container = decoder.userInfo._SwiftDB_DatabaseContainer else {
         fatalError()
         }
         
         guard let identifierType = Value.RelatableEntityType._opaque_ID as? Decodable.Type else {
         fatalError()
         }
         
         let decodedIDs = try identifierType.decodeArray(from: decoder)
         
         if decodedIDs.isEmpty {
         return
         } else {
         TODO.unimplemented
         }*/
    }
}
