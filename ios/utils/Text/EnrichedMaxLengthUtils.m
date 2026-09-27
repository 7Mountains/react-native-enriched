#import "EnrichedMaxLengthUtils.h"
#import "Strings.h"

@implementation EnrichedMaxLengthUtils

+ (NSInteger)plainLengthOf:(NSString *)text {
  return [self plainLengthOf:text inRange:NSMakeRange(0, text.length)];
}

+ (NSInteger)plainLengthOf:(NSString *)text inRange:(NSRange)range {
  NSInteger length = 0;
  NSUInteger index = range.location;
  NSUInteger end = NSMaxRange(range);

  while (index < end) {
    NSRange composed = [text rangeOfComposedCharacterSequenceAtIndex:index];
    BOOL isZeroWidthSpace =
        composed.length == 1 && [text characterAtIndex:index] == ZWSChar;

    if (!isZeroWidthSpace) {
      length++;
    }

    index = NSMaxRange(composed);
  }

  return length;
}

+ (NSInteger)capacityForText:(NSString *)text
              replacingRange:(NSRange)range
                   maxLength:(NSInteger)maxLength {
  if (maxLength == EnrichedMaxLengthUnlimited) {
    return NSIntegerMax;
  }

  NSRange safeRange = NSIntersectionRange(range, NSMakeRange(0, text.length));
  NSInteger keptLength =
      [self plainLengthOf:text] - [self plainLengthOf:text inRange:safeRange];

  return maxLength - keptLength;
}

+ (NSUInteger)cutIndexIn:(NSString *)text capacity:(NSInteger)capacity {
  NSUInteger index = 0;
  NSInteger kept = 0;

  while (index < text.length) {
    NSRange composed = [text rangeOfComposedCharacterSequenceAtIndex:index];
    BOOL isZeroWidthSpace =
        composed.length == 1 && [text characterAtIndex:index] == ZWSChar;

    if (!isZeroWidthSpace) {
      if (kept >= capacity) {
        break;
      }
      kept++;
    }

    index = NSMaxRange(composed);
  }

  return index;
}

+ (NSString *)truncate:(NSString *)text toCapacity:(NSInteger)capacity {
  if ([self plainLengthOf:text] <= capacity) {
    return text;
  }
  return [text substringToIndex:[self cutIndexIn:text capacity:capacity]];
}

@end
