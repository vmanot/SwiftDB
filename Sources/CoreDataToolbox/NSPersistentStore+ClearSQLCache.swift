import CoreData
import Runtime
import ObjectiveC

extension NSPersistentStore {
    @discardableResult
    public func resetSQLStoreCache() -> Bool {
        guard self.isKind(of: objc_lookUpClass("NSSQLCore")!) else {
            return false
        }

        guard let generationalRowCache,
              let oldPrimaryCache = generationalRowCache.primaryCache
        else {
            return false
        }

        let newPrimaryCache = object_getClass(oldPrimaryCache)!.alloc()._init(
            persistentStore: self
        ) as! NSObject
        generationalRowCache.primaryCache = newPrimaryCache

        //

        guard let dispatchManager,
              let connectionManagers = dispatchManager.connectionManagers?.compactMap(
                { $0 as? NSObject
                })
        else {
            return false
        }

        guard let image = DynamicLinkEditor.Image(filePath: "/System/Library/Frameworks/CoreData.framework/Versions/A/CoreData"),
              let rawSymbolIterator = image._rawSymbolIterator
        else {
            return false
        }

        var NSSQLiteConnection__clearCachedStatements: DynamicLinkEditor.Image.UnsafeRawSymbol?
        var NSSQLiteConnection__clearSaveGeneratedCachedStatements: DynamicLinkEditor.Image.UnsafeRawSymbol?
        var NSSQLiteStatementCache_clearCachedStatements: DynamicLinkEditor.Image.UnsafeRawSymbol?

        for rawSymbol in rawSymbolIterator {
            let name = rawSymbol.name

            if name == "-[NSSQLiteConnection _clearCachedStatements]" {
                NSSQLiteConnection__clearCachedStatements = rawSymbol
            } else if name == "-[NSSQLiteConnection _clearSaveGeneratedCachedStatements]" {
                NSSQLiteConnection__clearSaveGeneratedCachedStatements = rawSymbol
            } else if name == "-[NSSQLiteStatementCache clearCachedStatements]" {
                NSSQLiteStatementCache_clearCachedStatements = rawSymbol
            }

            if NSSQLiteConnection__clearCachedStatements != nil &&
                NSSQLiteConnection__clearSaveGeneratedCachedStatements != nil &&
                NSSQLiteStatementCache_clearCachedStatements != nil
            {
                break
            }
        }

        guard let NSSQLiteConnection__clearCachedStatements,
              let NSSQLiteConnection__clearSaveGeneratedCachedStatements,
              let NSSQLiteStatementCache_clearCachedStatements
        else {
            return false
        }

        for connectionManager in connectionManagers {
            guard connectionManager.isKind(of: objc_lookUpClass("NSSQLDefaultConnectionManager")!) else {
                continue
            }

            guard let allConnections = connectionManager.allConnections?.compactMap({ $0 as? NSObject }) else {
                continue
            }

            for connection in allConnections {
                guard let queue = connection.queue else {
                    continue
                }

                queue.sync {
                    NSSQLiteConnection__clearCachedStatements.address
                        .unsafeBitCast(to: (@convention(c) (AnyObject) -> Void).self)(connection)
                    NSSQLiteConnection__clearSaveGeneratedCachedStatements.address
                        .unsafeBitCast(to: (@convention(c) (AnyObject) -> Void).self)(connection)

                    guard let statementCachesByEntity = connection.statementCachesByEntity else{
                        return
                    }

                    let allValues = statementCachesByEntity.allValues.map({ $0 as AnyObject })
                    for cache in allValues {
                        NSSQLiteStatementCache_clearCachedStatements.address
                            .unsafeBitCast(to: (@convention(c) (AnyObject) -> Void).self)(cache)
                    }
                }
            }
        }

        return true
    }
}

// NSSQLCore
extension NSPersistentStore {
    fileprivate var generationalRowCache: NSObject? /* NSGenerationalRowCache */ {
        guard let ivar = objCClass[instanceVariableNamed: "_generationalRowCache"] else {
            return nil
        }

        return Unmanaged
            .passUnretained(self)
            .toOpaque()
            .advanced(by: ivar.offset)
            .assumingMemoryBound(to: NSObject.self)
            .pointee
    }

    fileprivate var dispatchManager: NSObject? /* NSSQLCoreDispatchManager */ {
        guard let ivar = objCClass[instanceVariableNamed: "_dispatchManager"] else {
            return nil
        }

        return Unmanaged
            .passUnretained(self)
            .toOpaque()
            .advanced(by: ivar.offset)
            .assumingMemoryBound(to: NSObject.self)
            .pointee
    }
}

// NSGenerationalRowCache
extension NSObject {
    fileprivate var primaryCache: NSObject? /* NSSQLRowCache */ {
        get {
            guard let ivar = objCClass[instanceVariableNamed: "_primaryCache"] else {
                return nil
            }

            return Unmanaged
                .passUnretained(self)
                .toOpaque()
                .advanced(by: ivar.offset)
                .assumingMemoryBound(to: NSObject.self)
                .pointee
        }
        set {
            guard let ivar = objCClass[instanceVariableNamed: "_primaryCache"] else {
                fatalError()
            }

            return Unmanaged
                .passUnretained(self)
                .toOpaque()
                .advanced(by: ivar.offset)
                .assumingMemoryBound(to: NSObject?.self)
                .pointee = newValue // pointee releases the old value and retain the new value
        }
    }
}

// NSSQLCoreDispatchManager
extension NSObject {
    fileprivate var connectionManagers: NSArray? /* NSArray<__kindof NSSQLConnectionManager *> */ {
        guard let ivar = objCClass[instanceVariableNamed: "_connectionManagers"] else {
            return nil
        }

        return Unmanaged
            .passUnretained(self)
            .toOpaque()
            .advanced(by: ivar.offset)
            .assumingMemoryBound(to: NSArray.self)
            .pointee
    }
}

// NSSQLDefaultConnectionManager
extension NSObject {
    fileprivate var allConnections: NSArray? /* NSArray<NSSQLiteConnection *> */ {
        guard let ivar = objCClass[instanceVariableNamed: "_allConnections"] else {
            return nil
        }

        return Unmanaged
            .passUnretained(self)
            .toOpaque()
            .advanced(by: ivar.offset)
            .assumingMemoryBound(to: NSArray.self)
            .pointee
    }
}

// NSSQLiteConnection
extension NSObject {
    fileprivate var queue: dispatch_queue_t? {
        guard let ivar = objCClass[instanceVariableNamed: "_queue"] else {
            return nil
        }

        return Unmanaged
            .passUnretained(self)
            .toOpaque()
            .advanced(by: ivar.offset)
            .assumingMemoryBound(to: dispatch_queue_t.self)
            .pointee
    }

    fileprivate var statementCachesByEntity: NSDictionary? /* NSDictionary<NSSQLEntity *, NSSQLiteStatementCache *> */ {
        guard let ivar = objCClass[instanceVariableNamed: "_statementCachesByEntity"] else {
            return nil
        }

        return Unmanaged
            .passUnretained(self)
            .toOpaque()
            .advanced(by: ivar.offset)
            .assumingMemoryBound(to: NSDictionary.self)
            .pointee
    }
}

// Selectors
extension NSObject {
    // -[NSSQLRowCache initWithPersistentStore:]
    @objc(initWithPersistentStore:) fileprivate func _init(persistentStore: NSPersistentStore) -> Self {
        fatalError("Do not Call")
    }
}
