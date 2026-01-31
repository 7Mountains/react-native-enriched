#import "ContentParams.h"
#import "HtmlAttributeNames.h"

@implementation ContentParams

+ (NSDictionary *)dictionaryFromJSONString:(id)jsonValue {
  if (![jsonValue isKindOfClass:NSString.class]) {
    return nil;
  }

  NSData *data = [(NSString *)jsonValue dataUsingEncoding:NSUTF8StringEncoding];
  if (!data)
    return nil;

  NSError *error = nil;
  id json = [NSJSONSerialization JSONObjectWithData:data
                                            options:0
                                              error:&error];

  if (!error && [json isKindOfClass:NSDictionary.class]) {
    return json;
  }

  return nil;
}

+ (nullable instancetype)paramsFromArgs:(NSArray *)args {
  if (![args isKindOfClass:[NSArray class]] || args.count < 5) {
    return nil;
  }

  ContentParams *params = [ContentParams new];

  // text
  if ([args[0] isKindOfClass:NSString.class]) {
    params.text = args[0];
  }

  // type
  if ([args[1] isKindOfClass:NSString.class]) {
    params.type = args[1];
  }

  // src
  if ([args[2] isKindOfClass:NSString.class]) {
    params.url = args[2];
  }

  // headers = JSON string
  NSDictionary *headersDict = [self dictionaryFromJSONString:args[3]];
  if (headersDict) {
    params.headers = headersDict;
  }

  // attributes = JSON string
  NSDictionary *attributesDict = [self dictionaryFromJSONString:args[4]];
  if (attributesDict) {
    params.attributes = attributesDict;
  }

  if (!params.type && !params.url && !params.text &&
      params.headers.count == 0 && params.attributes.count == 0) {
    return nil;
  }

  return params;
}

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
