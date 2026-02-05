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
  if (![args isKindOfClass:[NSArray class]] || args.count < 4) {
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

  // attributes = JSON string
  NSDictionary *attributesDict = [self dictionaryFromJSONString:args[3]];
  if (attributesDict) {
    params.attributes = attributesDict;
  }

  if (!params.type && !params.url && !params.text &&
      params.attributes.count == 0) {
    return nil;
  }

  return params;
}

@end
