#warning TODO: Rewrite using Swallow and Swift lang 

#import "NSPersistentStore+Category.h"
#include <objc/runtime.h>
#include <objc/message.h>
@import ellekit;

@implementation NSPersistentStore (Category)

+ (const void *)_cdImage {
    static const void *result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = MSGetImageByName("/System/Library/Frameworks/CoreData.framework/Versions/A/CoreData");
    });
    return result;
}

- (void)sql_resetCache {
    if (![self isKindOfClass:objc_lookUpClass("NSSQLCore")]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not kind of NSSQLCore" userInfo:nil];
    }
    
    id _generationalRowCache;
    assert(object_getInstanceVariable(self, "_generationalRowCache", (void **)&_generationalRowCache) != NULL);
    id oldPrimaryCache;
    assert(object_getInstanceVariable(_generationalRowCache, "_primaryCache", (void **)&oldPrimaryCache) != NULL);
    id newPrimaryCache = ((id (*)(id, SEL, id))objc_msgSend)([[oldPrimaryCache class] alloc], sel_registerName("initWithPersistentStore:"), self);
    [oldPrimaryCache release];
    assert(object_setInstanceVariable(_generationalRowCache, "_primaryCache", newPrimaryCache) != NULL);
    
    
    id _dispatchManager;
    assert(object_getInstanceVariable(self, "_dispatchManager", (void **)&_dispatchManager) != NULL);
    
    NSArray *_connectionManagers;
    assert(object_getInstanceVariable(_dispatchManager, "_connectionManagers", (void **)&_connectionManagers) != NULL);
    for (id connectionManager in _connectionManagers) {
        NSArray *_allConnections;
        assert(object_getInstanceVariable(connectionManager, "_allConnections", (void **)&_allConnections) != NULL);
        
        for (id connection in _allConnections) {
            const void *_clearCachedStatements = MSFindSymbol([NSPersistentStore _cdImage], "-[NSSQLiteConnection _clearCachedStatements]");
            const void *_clearSaveGeneratedCachedStatements = MSFindSymbol([NSPersistentStore _cdImage], "-[NSSQLiteConnection _clearSaveGeneratedCachedStatements]");
            const void *clearCachedStatements = MSFindSymbol([NSPersistentStore _cdImage], "-[NSSQLiteStatementCache clearCachedStatements]");
            
            dispatch_queue_t _queue;
            assert(object_getInstanceVariable(connection, "_queue", (void **)&_queue) != NULL);
            
            dispatch_sync(_queue, ^{
                ((void (*)(id))_clearCachedStatements)(connection);
                ((void (*)(id))_clearSaveGeneratedCachedStatements)(connection);
            });
            
            NSDictionary *_statementCachesByEntity;
            assert(object_getInstanceVariable(connection, "_statementCachesByEntity", (void **)&_statementCachesByEntity) != NULL);
            for (id cache in _statementCachesByEntity.allValues) {
                ((void (*)(id))clearCachedStatements)(cache);
            }
        }
    }
}

@end
