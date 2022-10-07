//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension _CloudKit.DatabaseRecord {
    public struct Asset {
        let ckAsset: CKAsset
        
        public init(asset: CKAsset) {
            self.ckAsset = asset
        }
        
        public func fileURL() throws -> URL {
            try ckAsset.fileURL.unwrap()
        }
    }
}
