#import "ContentParams.h"
#import "HtmlAttributeNames.h"

const int MAIN_ATTRIBUTES_COUNT = 3;

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

  // title
  if ([args[0] isKindOfClass:NSString.class]) {
    params.title = args[0];
  }

  // type
  if ([args[1] isKindOfClass:NSString.class]) {
    params.type = args[1];
  }

  // url
  if ([args[2] isKindOfClass:NSString.class]) {
    params.url = args[2];
  }

  // description
  if ([args[3] isKindOfClass:NSString.class]) {
    params.descriptionText = args[3];
  }

  // attributes = JSON string
  NSDictionary *attributesDict = [self dictionaryFromJSONString:args[4]];
  if (attributesDict) {
    params.attributes = attributesDict;
  }

  if (!params.type && !params.url && !params.title && !params.descriptionText &&
      params.attributes.count == 0) {
    return nil;
  }

  return params;
}

- (NSDictionary<NSString *, NSString *> *)toDictionary {
  NSUInteger capacity = _attributes.count + MAIN_ATTRIBUTES_COUNT;

  NSMutableDictionary *params =
      [NSMutableDictionary dictionaryWithCapacity:capacity];

  if (_type) {
    params[ContentTypeAttributeName] = _type;
  }

  if (_url) {
    params[ContentSrcAttributeName] = _url;
  }

  if (_title) {
    params[ContentTitleAttributeName] = _title;
  }

  if (_descriptionText) {
    params[ContentDescriptionTextAttrbiuteName] = _descriptionText;
  }

  if (_attributes.count > 0) {
    [params addEntriesFromDictionary:_attributes];
  }

  return params.count ? params : nil;
}

@end
