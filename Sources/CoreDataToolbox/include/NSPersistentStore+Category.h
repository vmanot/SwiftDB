#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSPersistentStore (Category)
- (void)sql_resetCache;
@end

NS_ASSUME_NONNULL_END
