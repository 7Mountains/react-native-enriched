@interface DividerRenderCache : NSObject

+ (instancetype)shared;

- (CGImageRef)cachedImageForKey:(NSString *)key;
- (void)setImage:(CGImageRef)image forKey:(NSString *)key;

@end
