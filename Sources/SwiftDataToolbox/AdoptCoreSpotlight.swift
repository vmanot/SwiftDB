import CoreData
import ObjectiveC.runtime
import Foundation

public func registerCoreSpotlight<T>(
    entityToProperties: [String: [String]],
    initializeBlock: () throws -> T
) rethrows -> T {
    let thread = Thread.current
    assert(thread.threadDictionary[key] == nil)
    thread.threadDictionary[key] = entityToProperties
    defer { thread.threadDictionary[key] = nil }

    return try initializeBlock()
}

fileprivate let key = "vmanot_swiftDB_entitiesToProperties"

@_cdecl("__vmanot_swiftDB_doNotCall_NSEntityDescription_load")
public func __vmanot_swiftDB_doNotCall_NSEntityDescription_load() {
    assert(original == nil)

    let method = class_getInstanceMethod(
        NSEntityDescription.self,
        #selector(setter: NSEntityDescription.properties)
    )!

    original = unsafeBitCast(method_getImplementation(method), to: type(of: original))
    method_setImplementation(method, unsafeBitCast(custom, to: IMP.self))
}

fileprivate var original: (@convention(c) (
    _ self: NSEntityDescription,
    _ cmd: Selector,
    _ properties: [NSPropertyDescription]
) -> Void)?

fileprivate let custom: (@convention(c) (
    _ self: NSEntityDescription,
    _ cmd: Selector,
    _ properties: [NSPropertyDescription]
) -> Void) = { `self`, cmd, properties in
    guard
        let name = self.name,
        let entitiesToProperties = Thread.current.threadDictionary[key] as? [String: [String]],
        let propertyNamesToPatch = entitiesToProperties[name]
    else {
        original!(self, cmd, properties)
        return
    }

    for case let attribute as NSAttributeDescription in properties {
        if propertyNamesToPatch.contains(attribute.name) {
            attribute.isIndexedBySpotlight = true
        }
    }

    original!(self, cmd, properties)
}
