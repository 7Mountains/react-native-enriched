#import "AlignmentConverter.h"

@implementation AlignmentConverter

+ (NSTextAlignment)alignmentFromString:(NSString *)string {
  if (string.length == 0)
    return NSTextAlignmentNatural;

  static NSDictionary<NSString *, NSNumber *> *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"left" : @(NSTextAlignmentLeft),
      @"right" : @(NSTextAlignmentRight),
      @"center" : @(NSTextAlignmentCenter),
      @"default" : @(NSTextAlignmentNatural),
      @"justify" : @(NSTextAlignmentJustified)
    };
  });

  NSNumber *value = map[string.lowercaseString];
  return value ? (NSTextAlignment)value.integerValue : NSTextAlignmentNatural;
}

+ (NSString *)stringFromAlignment:(NSTextAlignment)alignment {
  switch (alignment) {
  case NSTextAlignmentLeft:
    return @"left";
  case NSTextAlignmentRight:
    return @"right";
  case NSTextAlignmentCenter:
    return @"center";
  case NSTextAlignmentJustified:
    return @"justified";
  case NSTextAlignmentNatural:
  default:
    return @"default";
  }
}

@end
