//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Swallow

extension CKContainer {
    func database(for scope: CKDatabase.Scope) throws -> CKDatabase {
        switch scope {
            case .`public`:
                return publicCloudDatabase
            case .`private`:
                return privateCloudDatabase
            case .shared:
                return sharedCloudDatabase
                
            @unknown default:
                throw Never.Reason.unimplemented
        }
    }
}
