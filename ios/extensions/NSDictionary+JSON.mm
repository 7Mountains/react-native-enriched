#import "NSDictionary+JSON.h"

@implementation NSDictionary (JSON)

- (NSString *_Nullable)toJSONString {
  if (![NSJSONSerialization isValidJSONObject:self]) {
    return nil;
  }

  NSError *error = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                 options:0
                                                   error:&error];

  if (error || !data) {
    return nil;
  }

  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
