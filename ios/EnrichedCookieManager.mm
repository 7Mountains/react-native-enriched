#import "EnrichedCookieManager.h"

@interface EnrichedCookieManager ()
@property(atomic, strong)
    NSMutableDictionary<NSString *,
                        NSMutableDictionary<NSString *, NSString *> *> *store;
@end

@implementation EnrichedCookieManager

+ (instancetype)shared {
  static EnrichedCookieManager *shared;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [self new];
    shared.store = [NSMutableDictionary dictionary];
  });
  return shared;
}

- (void)setCookies:(NSArray<NSDictionary *> *)cookies {
  @synchronized(self) {
    [self.store removeAllObjects];

    for (NSDictionary *item in cookies) {
      NSString *domain = item[@"domain"];
      NSString *name = item[@"name"];
      NSString *value = item[@"value"];

      if (!domain.length || !name.length || !value.length)
        continue;

      NSMutableDictionary *domainCookies = self.store[domain];
      if (!domainCookies) {
        domainCookies = [NSMutableDictionary dictionary];
        self.store[domain] = domainCookies;
      }

      domainCookies[name] = value;
    }
  }
}

- (BOOL)domain:(NSString *)cookieDomain matchesHost:(NSString *)host {
  if ([host isEqualToString:cookieDomain])
    return YES;
  if ([cookieDomain hasPrefix:@"."] && [host hasSuffix:cookieDomain]) {
    return YES;
  }

  return NO;
}

- (NSString *)cookieHeaderForURL:(NSURL *)url {
  NSString *host = url.host;
  if (!host)
    return nil;

  NSMutableArray *parts = [NSMutableArray array];

  @synchronized(self) {
    [self.store enumerateKeysAndObjectsUsingBlock:^(
                    NSString *domain,
                    NSDictionary<NSString *, NSString *> *cookies, BOOL *stop) {
      if (![self domain:domain matchesHost:host])
        return;

      [cookies enumerateKeysAndObjectsUsingBlock:^(
                   NSString *name, NSString *value, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", name, value]];
      }];
    }];
  }

  return parts.count ? [parts componentsJoinedByString:@"; "] : nil;
}

@end
