#import "ContentParams.h"

@implementation ContentParams
+ (NSDictionary<NSString *, NSString *> *_Nullable)parseHeaderFromString:
    (NSString *)headerString {
  if (!headerString || headerString.length == 0)
    return @{};

  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  NSArray *parts = [headerString componentsSeparatedByString:@","];

  for (NSString *part in parts) {
    NSArray *kv = [part componentsSeparatedByString:@":"];

    if (kv.count < 2)
      continue;

    NSString *key = [[kv[0]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
        copy];

    NSString *value = [[[kv subarrayWithRange:NSMakeRange(1, kv.count - 1)]
        componentsJoinedByString:@":"]
        stringByTrimmingCharactersInSet:[NSCharacterSet
                                            whitespaceCharacterSet]];

    if (key.length > 0 && value.length > 0) {
      result[key] = value;
    }
  }

  return result;
}
@end
