#import "NSString+JSON.h"

@implementation NSString (JSON)

- (NSDictionary *_Nullable)jsonDictionary {
  if (self.length == 0) {
    return nil;
  }

  NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    return nil;
  }

  NSError *error = nil;
  id json =
      [NSJSONSerialization JSONObjectWithData:data
                                      options:NSJSONReadingMutableContainers
                                        error:&error];

  if (error || ![json isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  return (NSDictionary *)json;
}

@end
