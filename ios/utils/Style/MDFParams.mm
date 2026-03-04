#import "MDFParams.h"
#import "HtmlAttributeNames.h"

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

  id identification = dictionary[MDFIdAttributeName];
  if ([identification isKindOfClass:NSString.class]) {
    params.identification = identification;
  }

  id tintColor = dictionary[MDFTintColorAttributeName];
  if ([tintColor isKindOfClass:NSString.class]) {
    params.tintColor = tintColor;
  }

  return params;
}

- (NSDictionary<NSString *, NSString *> *)toDictionary {

  return @{
    MDFIdAttributeName : _identification,
    MDFLabelAttributeName : _label,
    MDFTintColorAttributeName : _tintColor
  };
}
@end
