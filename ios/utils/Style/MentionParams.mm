#import "MentionParams.h"

@implementation MentionParams

+ (instancetype)fromAttributes:(NSDictionary<NSString *, id> *)attributes {
  if (!attributes || attributes.count == 0) {
    return nil;
  }

  NSString *text = attributes[@"text"];
  NSString *indicator = attributes[@"indicator"];

  if (text.length == 0 || indicator.length == 0) {
    return nil;
  }

  MentionParams *params = [MentionParams new];
  params.text = text;
  params.indicator = indicator;

  NSMutableDictionary *extra = [attributes mutableCopy];
  [extra removeObjectForKey:@"text"];
  [extra removeObjectForKey:@"indicator"];

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
