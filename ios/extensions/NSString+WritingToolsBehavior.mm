#import "NSString+WritingToolsBehavior.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) &&                                \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= 180000
@implementation NSString (WritingToolsBehavior)

- (UIWritingToolsBehavior)writingToolsBehavior {
  NSString *behavior = self.lowercaseString;

  if ([behavior isEqualToString:@"disabled"]) {
    return UIWritingToolsBehaviorNone;
  }
  if ([behavior isEqualToString:@"complete"]) {
    return UIWritingToolsBehaviorComplete;
  }
  if ([behavior isEqualToString:@"limited"]) {
    return UIWritingToolsBehaviorLimited;
  }

  return UIWritingToolsBehaviorDefault;
}

@end
#endif
