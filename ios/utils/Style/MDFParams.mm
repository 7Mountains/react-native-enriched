#import "MDFParams.h"
#import "HtmlAttributeNames.h"

const int MAIN_ATTRIBUTES_COUNT = 2;

@implementation MDFParams

+ (instancetype)fromdDictionary:
    (NSDictionary<NSString *, NSString *> *)dictionary {
  if (dictionary.count == 0) {
    return nil;
  }

  MDFParams *params = [MDFParams new];

  id label = dictionary[MDFLabelAttributeName];
  if ([label isKindOfClass:NSString.class]) {
    params.label = label;
  }

  id tintColor = dictionary[MDFTintColorAttributeName];
  if ([tintColor isKindOfClass:NSString.class]) {
    params.tintColor = tintColor;
  }

  NSMutableDictionary *extra = dictionary.mutableCopy;
  [extra removeObjectsForKeys:@[
    MDFLabelAttributeName, MDFTintColorAttributeName
  ]];
  if ([extra isKindOfClass:NSDictionary.class]) {
    params.extraAttributes = extra;
  }

  return params;
}

- (NSDictionary<NSString *, NSString *> *)toDictionary {
  NSUInteger capacity = _extraAttributes.count + MAIN_ATTRIBUTES_COUNT;

  NSMutableDictionary *params =
      [NSMutableDictionary dictionaryWithCapacity:capacity];

  if (_label) {
    params[MDFLabelAttributeName] = _label;
  }

  if (_label) {
    params[MDFTintColorAttributeName] = _label;
  }

  if (_extraAttributes.count > 0) {
    [params addEntriesFromDictionary:_extraAttributes];
  }

  return params.count ? params : nil;
}
@end
