//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

final class NSPersistentContainerTests: XCTestCase {
    func testLoadPersistentStores() async throws {
        let container = NSPersistentContainer(
            name: "Test",
            managedObjectModel: NSManagedObjectModel()
        )

        let description1 = NSPersistentStoreDescription(url: Self.randomStoreURL())
        description1.shouldAddStoreAsynchronously = true
        description1.type = NSSQLiteStoreType

        let description2 = NSPersistentStoreDescription(url: Self.randomStoreURL())
        description2.shouldAddStoreAsynchronously = true
        description2.type = NSSQLiteStoreType

        container.persistentStoreDescriptions = [description1, description2]

        for await result in container.loadPersistentStores() {
            if let error = result.error {
                throw error
            }
        }

        XCTAssertEqual(container.persistentStoreCoordinator.persistentStores.count, 2)
    }

    func testLoadPersistentStoresWithError() async throws {
        let container = NSPersistentContainer(
            name: "Test",
            managedObjectModel: NSManagedObjectModel()
        )

        let description = NSPersistentStoreDescription(url: URL(filePath: "/boo"))
        description.shouldAddStoreAsynchronously = true
        description.type = NSSQLiteStoreType
        description.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.persistentStoreDescriptions = [description]

        var didCatch = false
        for await result in container.loadPersistentStores() {
            if let error = result.error {
                didCatch = true
            }
        }

        XCTAssertTrue(container.persistentStoreCoordinator.persistentStores.isEmpty)
        XCTAssertTrue(didCatch)
    }
}

extension NSPersistentContainerTests {
    private static func randomStoreURL() -> URL {
        let storeURL = FileManager
            .default
            .temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .notDirectory)
            .appendingPathExtension("sqlite")

        return storeURL
    }
}
