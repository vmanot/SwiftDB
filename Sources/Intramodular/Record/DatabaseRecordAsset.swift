//
// Copyright (c) Vatsal Manot
//

import Swift

/// A blob or an asset.
public protocol DatabaseRecordAsset {
    func fileURL() throws -> URL
}
