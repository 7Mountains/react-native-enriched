@implementation UIScrollView (KeyboardDismissModeParsing)

+ (UIScrollViewKeyboardDismissMode)fromString:(NSString *)value {
  if ([value isEqualToString:@"none"]) {
    return UIScrollViewKeyboardDismissModeNone;
  }
  if ([value isEqualToString:@"on-drag"]) {
    return UIScrollViewKeyboardDismissModeOnDrag;
  }
  if ([value isEqualToString:@"interactive"]) {
    return UIScrollViewKeyboardDismissModeInteractive;
  }

  return UIScrollViewKeyboardDismissModeNone;
}

@end