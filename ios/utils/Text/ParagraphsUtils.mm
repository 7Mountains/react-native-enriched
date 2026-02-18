#import "ParagraphsUtils.h"
#import "StyleHeaders.h"

@implementation ParagraphsUtils

#pragma mark - Public

+ (NSArray<NSValue *> *)getSeparateParagraphsRangesIn:(UITextView *)textView
                                                range:(NSRange)range {
  return [self separateParagraphRangesInString:textView.textStorage.string
                                         range:range];
}

+ (NSArray<NSValue *> *)
    getSeparateParagraphsRangesInAttributedString:
        (NSAttributedString *)attributedString
                                            range:(NSRange)range {
  return [self separateParagraphRangesInString:attributedString.string
                                         range:range];
}

+ (NSArray<NSValue *> *)getNonNewlineRangesIn:(UITextView *)textView
                                        range:(NSRange)range {
  NSString *string = textView.textStorage.string;
  NSMutableArray<NSValue *> *result = [NSMutableArray array];

  NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];

  NSUInteger searchLocation = range.location;
  NSUInteger end = NSMaxRange(range);

  while (searchLocation < end) {
    NSRange searchRange = NSMakeRange(searchLocation, end - searchLocation);

    NSRange newlineRange = [string rangeOfCharacterFromSet:newlineSet
                                                   options:0
                                                     range:searchRange];

    if (newlineRange.location == NSNotFound) {
      [result addObject:[NSValue valueWithRange:searchRange]];
      break;
    }

    if (newlineRange.location > searchLocation) {
      [result
          addObject:[NSValue valueWithRange:NSMakeRange(searchLocation,
                                                        newlineRange.location -
                                                            searchLocation)]];
    }

    searchLocation = NSMaxRange(newlineRange);
  }

  return result;
}

+ (BOOL)isReadOnlyParagraphAtLocation:(NSAttributedString *)attributedString
                             location:(NSUInteger)location {
  NSUInteger length = attributedString.length;
  if (length == 0)
    return NO;

  if (location > 0) {
    if ([attributedString attribute:ReadOnlyParagraphKey
                            atIndex:location - 1
                     effectiveRange:nil]) {
      return YES;
    }
  }

  if (location < length) {
    if ([attributedString attribute:ReadOnlyParagraphKey
                            atIndex:location
                     effectiveRange:nil]) {
      return YES;
    }
  }

  return NO;
}

+ (NSArray<NSValue *> *)separateParagraphRangesInString:(NSString *)string
                                                  range:(NSRange)range {
  NSRange fullRange = [string paragraphRangeForRange:range];
  if (fullRange.length == 0) {
    return @[ [NSValue valueWithRange:fullRange] ];
  }

  NSMutableArray<NSValue *> *results = [NSMutableArray array];

  [string
      enumerateSubstringsInRange:fullRange
                         options:NSStringEnumerationByParagraphs |
                                 NSStringEnumerationSubstringNotRequired
                      usingBlock:^(
                          NSString *_Nullable substring, NSRange substringRange,
                          NSRange enclosingRange, BOOL *_Nonnull stop) {
                        [results
                            addObject:[NSValue valueWithRange:substringRange]];
                      }];

  return results;
}

@end
