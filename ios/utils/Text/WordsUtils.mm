#import "WordsUtils.h"
#import "AffectedWord.h"

@implementation WordsUtils

+ (NSArray<AffectedWord *> *)getAffectedWordsFromText:(NSString *)text
                                    modificationRange:(NSRange)range {
  if (text.length == 0) {
    return [[NSArray alloc] init];
  }

  NSInteger leftIt = range.location - 1;
  leftIt = MIN(leftIt, NSInteger(text.length - 1));
  if (leftIt > 0) {
    while (leftIt >= 0) {
      unichar charAtIndex = [text characterAtIndex:leftIt];
      if ([[NSCharacterSet whitespaceAndNewlineCharacterSet]
              characterIsMember:charAtIndex]) {
        leftIt += 1;
        break;
      }
      leftIt -= 1;
    }
  }
  leftIt = MAX(0, leftIt);
  leftIt = MIN(NSInteger(text.length - 1), leftIt);

  NSInteger rightIt = range.location + range.length;
  if (rightIt < text.length - 1) {
    while (rightIt <= text.length - 1) {
      unichar charAtIndex = [text characterAtIndex:rightIt];
      if ([[NSCharacterSet whitespaceAndNewlineCharacterSet]
              characterIsMember:charAtIndex]) {
        rightIt -= 1;
        break;
      }
      rightIt += 1;
    }
  }
  rightIt = MIN(NSInteger(text.length - 1), rightIt);

  if (leftIt > rightIt) {
    return [[NSArray alloc] init];
  }

  NSMutableArray<AffectedWord *> *separatedWords =
      [[NSMutableArray<AffectedWord *> alloc] init];
  NSMutableString *currentWord = [[NSMutableString alloc] init];
  NSInteger currentRangeStart = leftIt;
  NSInteger currentIdx = leftIt;

  while (currentIdx <= rightIt) {
    unichar charAtIndex = [text characterAtIndex:currentIdx];
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet]
            characterIsMember:charAtIndex]) {
      if (currentWord.length > 0) {

        AffectedWord *affectedWord = [[AffectedWord alloc]
            initWithText:[currentWord copy]
                   range:NSMakeRange(currentRangeStart, currentWord.length)];
        [separatedWords addObject:affectedWord];
        [currentWord setString:@""];
      }
      currentRangeStart = currentIdx + 1;
    } else {
      [currentWord appendFormat:@"%C", charAtIndex];
    }
    currentIdx += 1;
  }

  if (currentWord.length > 0) {
    AffectedWord *affectedWord = [[AffectedWord alloc]
        initWithText:[currentWord copy]
               range:NSMakeRange(currentRangeStart,
                                 rightIt - currentRangeStart + 1)];
    [separatedWords addObject:affectedWord];
  }

  return separatedWords;
}

+ (AffectedWord *)getCurrentWord:(NSString *)text range:(NSRange)range {
  // we just get current word at the cursor
  if (range.length > 0) {
    return nullptr;
  }

  NSArray<AffectedWord *> *words = [WordsUtils getAffectedWordsFromText:text
                                                      modificationRange:range];
  if (words != nullptr && [words count] == 1 &&
      [words firstObject] != nullptr) {
    return [words firstObject];
  }

  return nullptr;
}

@end
