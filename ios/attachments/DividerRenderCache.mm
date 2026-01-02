#import "DividerRenderCache.h"

@implementation DividerRenderCache {
  NSCache<NSString *, id> *_cache;
}

+ (instancetype)shared {
  static DividerRenderCache *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[DividerRenderCache alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _cache = [[NSCache alloc] init];
    // we have only one divider image per text view
    _cache.countLimit = 1;
    _cache.totalCostLimit = 0;
  }
  return self;
}

- (CGImageRef)cachedImageForKey:(NSString *)key {
  return (__bridge CGImageRef)[_cache objectForKey:key];
}

- (void)setImage:(CGImageRef)image forKey:(NSString *)key {
  if (!image || !key)
    return;

  [_cache setObject:(__bridge id)image forKey:key];
}

@end
