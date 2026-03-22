#import "KeyPressConverter.h"
#import "Strings.h"

@implementation KeyPressConverter

+ (NSString *)keyFromText:(NSString *)text range:(NSRange)range {
  if (text.length == 0 && range.length > 0) {
    return @"Backspace";
  } else if ([text isEqualToString:NewLine]) {
    return @"Enter";
  } else if ([text isEqualToString:Tab]) {
    return @"Tab";
  } else if (text.length == 1) {
    return text;
  }
  return nil;
}

@end
