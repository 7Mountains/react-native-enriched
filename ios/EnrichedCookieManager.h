@interface EnrichedCookieManager : NSObject

+ (instancetype)shared;

- (void)setCookies:(NSArray<NSDictionary *> *)cookies;

- (NSString *)cookieHeaderForURL:(NSURL *)url;

@end
