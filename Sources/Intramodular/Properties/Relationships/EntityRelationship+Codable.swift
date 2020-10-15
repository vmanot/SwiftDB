//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow
import SwiftUI

extension EntityRelationship {
	private var modelIDs: [AnyEncodable] {
		guard Value.RelatableEntityType._opaque_ID is Codable.Type else {
			assertionFailure()
			
			return []
		}
		
		return try! wrappedValue.exportRelatableModels().map({ .init($0._opaque_id!.base as! Codable) })
	}
	
	public func encode(to encoder: Encoder) throws {
		try modelIDs.encode(to: encoder)
	}
	
	public func decode(from decoder: Decoder) throws {
		guard let identifierType = Value.RelatableEntityType._opaque_ID as? Decodable.Type else {
			assertionFailure()
			
			return
		}
		
		let decodedIDs = try identifierType.decodeArray(from: decoder)
		
		if decodedIDs.isEmpty {
			return
		} else {
			TODO.unimplemented
		}
	}
}

extension Decodable {
	public static func decodeArray(from decoder: Decoder) throws -> [Decodable] {
		try decoder.decode(single: [Self].self)
	}
}
