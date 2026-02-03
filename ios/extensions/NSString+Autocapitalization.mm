#import "NSString+Autocapitalization.h"

@implementation NSString (Autocapitalization)

- (UITextAutocapitalizationType)autocapitalizationType {
  static NSDictionary<NSString *, NSNumber *> *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"none" : @(UITextAutocapitalizationTypeNone),
      @"sentences" : @(UITextAutocapitalizationTypeSentences),
      @"words" : @(UITextAutocapitalizationTypeWords),
      @"characters" : @(UITextAutocapitalizationTypeAllCharacters)
    };
  });

  NSNumber *value = map[self.lowercaseString];
  return value ? (UITextAutocapitalizationType)value.integerValue
               : UITextAutocapitalizationTypeNone;
}

@end
