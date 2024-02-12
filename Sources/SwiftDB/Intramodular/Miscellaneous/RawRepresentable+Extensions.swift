//
// Copyright (c) Vatsal Manot
//

import Swallow

extension RawRepresentable {
    static var _opaque_RawValue: Any.Type {
        RawValue.self
    }
    
    init?(_opaque_rawValue rawValue: Any) throws {
        self.init(rawValue: try cast(rawValue, to: RawValue.self))
    }
}
