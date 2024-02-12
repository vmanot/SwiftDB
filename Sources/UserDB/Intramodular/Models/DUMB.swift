//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import SwiftDB
import SwiftUI
import UniformTypeIdentifiers

/// The DUMB (.dmb) file format.
public struct _DUMB: Codable, Hashable, Sendable {
    public let encodingVersion: Version
}

// MARK: - Conformances

extension _DUMB: FileDocument {
    public static var readableContentTypes: [UTType] {
        [.dumb]
    }
    
    public static var writableContentTypes: [UTType] {
        [.dumb]
    }
    
    public init(configuration: ReadConfiguration) throws {
        fatalError()
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        fatalError()
    }
}


extension UTType {
    /// A type that represents a DUMB file.
    public static let dumb = UTType(exportedAs: "com.vmanot.DUMB")
}
