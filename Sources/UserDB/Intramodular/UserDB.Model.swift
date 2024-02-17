//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import SwiftDB

public protocol __UserDB_Model: Identifiable where ID: PersistentIdentifier {
    
}

extension UserDB {
    public typealias Model = __UserDB_Model
}
