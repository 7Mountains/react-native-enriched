#import "EnrichedMaxLengthUtils.h"
#import "Strings.h"

@implementation EnrichedMaxLengthUtils

+ (NSInteger)plainLengthOf:(NSString *)text {
  return [self plainLengthOf:text inRange:NSMakeRange(0, text.length)];
}

+ (NSInteger)plainLengthOf:(NSString *)text inRange:(NSRange)range {
  NSInteger length = 0;
  for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
    if ([text characterAtIndex:i] != ZWSChar) {
      length++;
    }
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
    if ([text characterAtIndex:index] != ZWSChar) {
      // zero width spaces are free, any other character needs the capacity
      if (kept >= capacity) {
        break;
      }
      kept++;
    }
    index++;
  }

  if (index == 0 || index == text.length) {
    return index;
  }

  // never cut a composed character in half - snap
  // the cut point outwards instead
  NSRange composed = [text rangeOfComposedCharacterSequenceAtIndex:index];
  return composed.location == index ? index : NSMaxRange(composed);
}

+ (NSString *)truncate:(NSString *)text toCapacity:(NSInteger)capacity {
  if ([self plainLengthOf:text] <= capacity) {
    return text;
  }
  return [text substringToIndex:[self cutIndexIn:text capacity:capacity]];
}

@end
