#import "EnrichedMaxLengthUtils.h"
#import "Strings.h"

@implementation EnrichedMaxLengthUtils

+ (NSInteger)plainLengthOf:(NSString *)text {
  return [self plainLengthOf:text inRange:NSMakeRange(0, text.length)];
}

+ (NSInteger)plainLengthOf:(NSString *)text inRange:(NSRange)range {
  NSInteger length = 0;
  for (NSUInteger index = range.location; index < NSMaxRange(range); index++) {
    if ([text characterAtIndex:index] != ZWSChar) {
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
    NSRange composed = [text rangeOfComposedCharacterSequenceAtIndex:index];
    NSInteger composedLength = [self plainLengthOf:text inRange:composed];

    // Capacity is measured in UTF-16 code units, but composed character
    // sequences are atomic and must either fit completely or be omitted.
    if (kept + composedLength > capacity) {
      break;
    }

    kept += composedLength;
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
