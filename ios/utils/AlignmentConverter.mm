#import "AlignmentConverter.h"

static NSString *const LeftAlignmentString = @"left";
static NSString *const RightAlignmentString = @"right";
static NSString *const CenterAlignmentString = @"center";
static NSString *const JustifyAlignmentString = @"justify";
static NSString *const NeuturalAlignmentString = @"default";

@implementation AlignmentConverter

+ (NSTextAlignment)alignmentFromString:(NSString *)string {
  if (string.length == 0)
    return NSTextAlignmentNatural;

  static NSDictionary<NSString *, NSNumber *> *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      LeftAlignmentString : @(NSTextAlignmentLeft),
      RightAlignmentString : @(NSTextAlignmentRight),
      CenterAlignmentString : @(NSTextAlignmentCenter),
      NeuturalAlignmentString : @(NSTextAlignmentNatural),
      JustifyAlignmentString : @(NSTextAlignmentJustified)
    };
  });

  NSNumber *value = map[string.lowercaseString];
  return value ? (NSTextAlignment)value.integerValue : NSTextAlignmentNatural;
}

+ (NSString *)stringFromAlignment:(NSTextAlignment)alignment {
  switch (alignment) {
  case NSTextAlignmentLeft:
    return LeftAlignmentString;
  case NSTextAlignmentRight:
    return RightAlignmentString;
  case NSTextAlignmentCenter:
    return CenterAlignmentString;
  case NSTextAlignmentJustified:
    return JustifyAlignmentString;
  case NSTextAlignmentNatural:
  default:
    return NeuturalAlignmentString;
  }
}

@end
