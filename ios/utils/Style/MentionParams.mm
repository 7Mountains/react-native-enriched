#import "MentionParams.h"
#import "HtmlAttributeNames.h"

@implementation MentionParams

+ (instancetype)fromAttributes:(NSDictionary<NSString *, id> *)attributes {
  if (!attributes || attributes.count == 0) {
    return nil;
  }

  NSString *text = attributes[MentionTextAttributeName];
  NSString *indicator = attributes[MentionIndicatorAttributeName];
  NSString *type = attributes[MentionTypeAttributeName];

  if (text.length == 0 || indicator.length == 0) {
    return nil;
  }

  MentionParams *params = [MentionParams new];
  params.text = text;
  params.indicator = indicator;
  params.type = type;

  NSMutableDictionary *extra = [attributes mutableCopy];
  [extra removeObjectForKey:MentionTextAttributeName];
  [extra removeObjectForKey:MentionIndicatorAttributeName];
  [extra removeObjectForKey:MentionTypeAttributeName];

  params.extraAttributes = extra;

  return params;
}

- (BOOL)isEqualToMentionParams:(MentionParams *)other {
  if (self == other)
    return YES;
  if (!other)
    return NO;

  BOOL sameText =
      (self.text == other.text) || [self.text isEqualToString:other.text];

  BOOL sameIndicator = (self.indicator == other.indicator) ||
                       [self.indicator isEqualToString:other.indicator];

  BOOL sameAttributes =
      (self.extraAttributes == other.extraAttributes) ||
      [self.extraAttributes isEqualToDictionary:other.extraAttributes];

  return sameText && sameIndicator && sameAttributes;
}

@end
